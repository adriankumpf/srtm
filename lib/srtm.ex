defmodule SRTM do
  @moduledoc """
  A simple interface to query locations on the Earth for elevation data from the NASA Shuttle Radar
  Topography Mission (SRTM).
  """

  alias __MODULE__.Cache
  alias __MODULE__.DataCell
  alias __MODULE__.Error
  alias __MODULE__.Source

  @default_cache_path "./srtm_cache"

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
      {:ok, -51}}

  ## Configuration

  - `:disk_cache_enabled` (`t:boolean/0`) - whehter the disk cache is enabled.

  - `:disk_cache_path` (`t:Path.t/0`) - the path to the directory where the downloaded HGT files are
    stored. Defaults to `#{@default_cache_path}`.

  - `:in_memory_cache_enabled` (`t:boolean/0`) - whehter the in-memory cache is enabled.

      > #### Note {: .warning}
      >
      > See `SRTM.Cache.PersistentTerm` for the implications on system performance.

  - `:in_memory_cache_module` (`t:module/0`) - A module that implements the `SRTM.Cache` behaviour.
    Defaults to `SRTM.Cache.PersistentTerm`.

  - `:sources` (list of `t:module/0`) - a list of modules that implement the `SRTM.Source`
    behaviour. Defaults to `SRTM.Source.AWS` and `SRTM.Source.ESA`.

  """
  @spec get_elevation(latitude, longitude, keyword()) ::
          {:ok, elevation | nil} | {:error, Error.t()}
  def get_elevation(latitude, longitude, opts \\ []) do
    case get_data_cell({latitude, longitude}, opts) do
      {:ok, data_cell} ->
        elevation = DataCell.get_elevation(data_cell, latitude, longitude)
        {:ok, elevation}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_data_cell({latitude, longitude}, opts) do
    in_memory_cache_enabled = Keyword.get(opts, :in_memory_cache_enabled, true)
    in_memory_cache_module = Keyword.get(opts, :in_memory_cache_module, Cache.PersistentTerm)

    disk_cache_enabled = Keyword.get(opts, :disk_cache_enabled, true)
    disk_cache_path = Keyword.get(opts, :disk_cache_path, @default_cache_path)

    sources = opts[:sources] || [Source.AWS, Source.ESA]

    caches =
      Enum.reject(
        [
          if(in_memory_cache_enabled, do: in_memory_cache_module),
          if(disk_cache_enabled, do: Cache.File)
        ],
        &is_nil/1
      )

    hgt_name = hgt_name(latitude, longitude)
    hgt_path = Path.join(disk_cache_path, hgt_name <> ".hgt")

    with :error <- lookup_from_cache(hgt_path, caches),
         {:ok, data_cell} <- download_data_cell(hgt_name, sources),
         :ok <- cache_data_cell(hgt_path, data_cell, caches) do
      {:ok, data_cell}
    end
  end

  defp lookup_from_cache(_hgt_path, []) do
    message = "There are no configured caches."
    {:error, %Error{reason: :missing_caches, message: message}}
  end

  defp lookup_from_cache(hgt_path, caches) do
    {_, result} =
      Enum.reduce_while(caches, {[], :error}, fn cache, {higher_caches, _} ->
        case cache.fetch(hgt_path) do
          :error ->
            {:cont, {[cache | higher_caches], :error}}

          {:ok, data_cell} ->
            result =
              with :ok <- cache_data_cell(hgt_path, data_cell, higher_caches) do
                {:ok, data_cell}
              end

            {:halt, {[], result}}
        end
      end)

    result
  end

  defp cache_data_cell(hgt_path, data_cell, caches) do
    Enum.reduce_while(caches, :ok, fn cache, _ ->
      case cache.store(hgt_path, data_cell) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
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
