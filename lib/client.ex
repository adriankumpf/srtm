defmodule SRTM.Client do
  @moduledoc """
  The client for querying elevation data.
  """

  alias __MODULE__, as: Client
  alias SRTM.{Error, DataCell, Source}

  defstruct [:client, :cache_path, :data_cells, :sources]

  @opaque t :: %__MODULE__{
            client: Tesla.Client.t(),
            cache_path: String.t(),
            data_cells: map,
            sources: Keyword.t()
          }

  @adapter {Tesla.Adapter.Hackney, pool: :srtm}

  @doc """
  Creates a client struct that holds configuration and parsed HGT files.

  If the directory at the given `path` doesn't exist, creates it.

  ## Options

  The supported options are:

  * `:sources` (list of `t:module/0`) - the SRTM source providers (defaults to `SRTM.Source.AWS` and `SRTM.Source.ESA`)
  * `:adapter` (`t:module/0`) - the [Tesla adapter](https://hexdoks.pm/tesla/readme.html) for
    the API client (default: `#{inspect(@adapter)}`)
  * `:opts` (`t:keyword/0`) – default opts for all requests (default: `[]`)

  ## Examples

      iex> {:ok, client} = SRTM.Client.new("./cache")
      {:ok, %SRTM.Client{}}

      iex> finch_adapter = {Tesla.Adapter.Finch, name: MyFinch, receive_timeout: 30_000}
      iex> {:ok, client} = SRTM.Client.new("./cache", adapter: finch_adapter)
      {:ok, %SRTM.Client{}}

  """
  @spec new(path :: Path.t(), opts :: Keyword.t()) :: {:ok, t} | {:error, error :: Error.t()}
  def new(path, opts \\ []) do
    sources = Keyword.get(opts, :sources, [Source.AWS, Source.ESA])
    path = Path.expand(path)

    case File.mkdir_p(path) do
      {:error, reason} ->
        {:error, %Error{reason: :io_error, message: "Creation of #{path} failed: #{reason}"}}

      :ok ->
        adapter = opts[:adapter] || @adapter
        opts = opts[:opts] || []

        middleware = [
          {Tesla.Middleware.Headers, [{"user-agent", "github.com/adriankumpf/srtm"}]},
          {Tesla.Middleware.Opts, opts}
        ]

        client = Tesla.client(middleware, adapter)

        {:ok, %__MODULE__{client: client, cache_path: path, data_cells: %{}, sources: sources}}
    end
  end

  @doc """
  Removes parsed HGT files from the in-memory cache.

  ## Options

  The supported options are:

  * `:keep` - the number of most recently used HGT files to keep (default: 0)

  ## Examples

      iex> {:ok, client} = SRTM.Client.purge_in_memory_cache(client, keep: 1)
      {:ok, %SRTM.Client{}}

  """
  @spec purge_in_memory_cache(t, keyword) :: {:ok, t}
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
