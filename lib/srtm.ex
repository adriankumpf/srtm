defmodule SRTM do
  @moduledoc """
  A simple interface to query locations on the Earth for elevation data from the NASA Shuttle Radar
  Topography Mission (SRTM).
  """

  alias __MODULE__.Cache
  alias __MODULE__.DataCell
  alias __MODULE__.Error
  alias __MODULE__.Source

  @default_opts [
    disk_cache_enabled: true,
    disk_cache_path: "./srtm_cache",
    in_memory_cache_enabled: true,
    in_memory_cache_module: Cache.PersistentTerm,
    sources: [Source.AWS, Source.ESA]
  ]

  @typedoc """
  A geographic coordinate that specifies the north–south position of a point on the surface of the
  Earth.
  """
  @type latitude :: number()

  @typedoc """
  A geographic coordinate that specifies the east–west position of a point on the surface of the
  Earth.
  """
  @type longitude :: number()

  @typedoc "Elevation (in meters)"
  @type elevation :: integer()

  @doc """
  Queries locations on the earth for elevation data.

  If the corresponding file can't be found in the cache, it will be retrieved online.

  Returns the elevation in meters.

  ## Examples

      iex> SRTM.get_elevation(36.455556, -116.866667)
      {:ok, -51}

  ## Configuration

  Unknown options raise an `ArgumentError`.

  - `:disk_cache_enabled` (`t:boolean/0`) - whether the disk cache is enabled. Defaults to
    `#{@default_opts[:disk_cache_enabled]}`.

  - `:disk_cache_path` (`t:Path.t/0`) - the path to the directory where the downloaded HGT files are
    stored. Defaults to `#{@default_opts[:disk_cache_path]}`.

  - `:in_memory_cache_enabled` (`t:boolean/0`) - whether the in-memory cache is enabled. Defaults to
    `#{@default_opts[:in_memory_cache_enabled]}`.

      > #### Note {: .warning}
      >
      > See `SRTM.Cache.PersistentTerm` for the implications on system performance.

  - `:in_memory_cache_module` (`t:module/0`) - a module that implements the `SRTM.Cache` behaviour.
    Defaults to `#{inspect(@default_opts[:in_memory_cache_module])}`.

  - `:sources` (list of `t:module/0` or `{module, keyword}`) - a list of modules that implement the
    `SRTM.Source` behaviour, tried in order. Defaults to
    `#{inspect(@default_opts[:sources])}`. See the source modules for the options they accept.

  With both caches disabled, every lookup downloads the HGT file.

  """
  @spec get_elevation(latitude, longitude, keyword()) ::
          {:ok, elevation | nil} | {:error, Error.t()}
  def get_elevation(latitude, longitude, opts \\ []) do
    opts = Keyword.validate!(opts, @default_opts)

    with {:ok, data_cell} <- get_data_cell(latitude, longitude, opts) do
      {:ok, DataCell.get_elevation(data_cell, latitude, longitude)}
    end
  end

  defp get_data_cell(latitude, longitude, opts) do
    # Ordered from cheapest to most expensive.
    caches =
      for {enabled?, cache} <- [
            {opts[:in_memory_cache_enabled], opts[:in_memory_cache_module]},
            {opts[:disk_cache_enabled], Cache.File}
          ],
          enabled?,
          do: cache

    hgt_name = hgt_name(latitude, longitude)
    hgt_path = Path.join(opts[:disk_cache_path], hgt_name <> ".hgt")

    with :error <- fetch_from_caches(hgt_path, caches, []),
         {:ok, data_cell} <- download_data_cell(hgt_name, opts[:sources]),
         :ok <- store_in_caches(hgt_path, data_cell, caches) do
      {:ok, data_cell}
    end
  end

  defp fetch_from_caches(_hgt_path, [], _missed), do: :error

  defp fetch_from_caches(hgt_path, [cache | caches], missed) do
    case cache.fetch(hgt_path) do
      :error ->
        fetch_from_caches(hgt_path, caches, [cache | missed])

      # Backfill the caches that missed, so the next lookup stops at the cheapest one.
      {:ok, data_cell} ->
        with :ok <- store_in_caches(hgt_path, data_cell, missed), do: {:ok, data_cell}
    end
  end

  defp store_in_caches(hgt_path, data_cell, caches) do
    Enum.reduce_while(caches, :ok, fn cache, :ok ->
      case cache.store(hgt_path, data_cell) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp download_data_cell(_hgt_name, []) do
    message = "There are no configured sources."
    {:error, %Error{reason: :missing_sources, message: message}}
  end

  defp download_data_cell(hgt_name, sources) do
    sources
    |> Enum.map(fn
      {source, opts} -> {source, opts}
      source -> {source, []}
    end)
    |> Enum.reduce_while(nil, fn {source, opts}, _ ->
      case source.fetch(hgt_name, opts) do
        {:ok, hgt_data} -> {:halt, DataCell.new(hgt_name, hgt_data)}
        error -> {:cont, error}
      end
    end)
  end

  defp hgt_name(lat, lng) do
    if(lat >= 0, do: "N", else: "S") <>
      (lat |> floor() |> abs() |> pad(2)) <>
      if(lng >= 0, do: "E", else: "W") <>
      (lng |> floor() |> abs() |> pad(3))
  end

  defp pad(num, count), do: num |> Integer.to_string() |> String.pad_leading(count, "0")
end
