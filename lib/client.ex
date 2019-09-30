defmodule SRTM.Client do
  @moduledoc """
  This module holds the client for querying elevation data.
  """

  alias __MODULE__, as: Client
  alias SRTM.{Error, DataCell, Source}

  defstruct [:client, :cache_path, :data_cells, :sources]

  @opaque t :: %__MODULE__{
            client: Tesla.Client.t(),
            cache_path: String.t(),
            data_cells: map,
            sources: list
          }

  @doc """
  Creates a client struct that holds configuration and parsed HGT files.

  If the directory at the given `path` doesn't exist, creates it.

  ## Options

  The supported options are:

  * `:sources` - the SRTM source providers (defaults to
    [AWS](https://registry.opendata.aws/terrain-tiles/) and
    [ESA](http://step.esa.int/auxdata/dem/SRTMGL1/) and
    [USGS](https://dds.cr.usgs.gov/srtm/version2_1/))

  ## Examples

      iex> SRTM.Client.new("./cache")
      {:ok, %SRTM.Client{}}

  """
  @spec new(path :: Path.t(), opts :: list) :: {:ok, t} | {:error, error :: Error.t()}
  def new(path, opts \\ []) do
    sources =
      case Keyword.get(opts, :sources) do
        [_ | _] = sources -> sources
        _ -> [Source.AWS, Source.ESA, Source.USGS]
      end

    path = Path.expand(path)

    case File.mkdir_p(path) do
      {:error, reason} ->
        {:error, %Error{reason: :io_error, message: "Creation of #{path} failed: #{reason}"}}

      :ok ->
        middleware = [
          {Tesla.Middleware.Headers, [{"user-agent", "github.com/adriankumpf/srtm"}]}
        ]

        client = Tesla.client(middleware, {Tesla.Adapter.Mint, recv_timeout: 30_000})

        {:ok, %__MODULE__{client: client, cache_path: path, data_cells: %{}, sources: sources}}
    end
  end

  @doc """
  Removes parsed HGT files from the in-memory cache.

  ## Options

  The supported options are:

  * `:keep` - the number of most recently used HGT files to keep (default: 0)

  ## Examples

      iex> SRTM.Client.purge_in_memory_cache(client, keep: 1)
      {:ok, %SRTM.Client{}}
  """
  @spec purge_in_memory_cache(client :: t, opts :: list) :: {:ok, t}
  def purge_in_memory_cache(%Client{} = client, opts \\ []) do
    keep = Keyword.get(opts, :keep, 0)

    purged_data_cells =
      client.data_cells
      |> Enum.sort_by(fn {_, {:ok, %DataCell{last_used: d}}} -> d end, &order_by_date_desc/2)
      |> Enum.take(keep)
      |> Enum.into(%{})

    {:ok, %Client{client | data_cells: purged_data_cells}}
  end

  @doc false
  def get_elevation(%Client{} = client, latitude, longitude) do
    case get_data_cell(client, {latitude, longitude}) do
      {:ok, %DataCell{} = dc, %Client{} = client} ->
        elevation = DataCell.get_elevation(dc, latitude, longitude)
        {:ok, elevation, client}

      {:error, :out_of_bounds} ->
        {:ok, nil, client}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_data_cell(%Client{data_cells: data_cells, sources: sources} = client, {lat, lng}) do
    {cell_lat, cell_lng} = {floor(lat), floor(lng)}

    load_cell = fn ->
      with {:ok, hgt_path} <- fetch([Source.Cache | sources], [client, {lat, lng}]) do
        DataCell.from_file(hgt_path)
      end
    end

    with {:ok, data_cell} <- Map.get_lazy(data_cells, {lat, lng}, load_cell) do
      data_cell = %DataCell{data_cell | last_used: DateTime.utc_now()}
      data_cells = Map.put(data_cells, {cell_lat, cell_lng}, {:ok, data_cell})
      {:ok, data_cell, %Client{client | data_cells: data_cells}}
    end
  end

  defp fetch(sources, args, acc \\ {:error, :unreachable})
  defp fetch(_sources, _args, {:ok, hgt_file}), do: {:ok, hgt_file}
  defp fetch([], _args, {:error, reason}), do: {:error, reason}
  defp fetch([source | rest], args, _acc), do: fetch(rest, args, apply(source, :fetch, args))

  defp order_by_date_desc(d0, d1) do
    case DateTime.compare(d0, d1) do
      :gt -> true
      _ -> false
    end
  end
end
