defmodule SRTM.Client do
  @moduledoc """
  This module holds the client for querying elevation data.
  """

  alias __MODULE__, as: Client
  alias SRTM.{Error, DataCell}

  defstruct [:client, :cache_path, :data_cells, :source]

  @opaque t :: %__MODULE__{
            client: Tesla.Client.t(),
            cache_path: String.t(),
            data_cells: map,
            source: atom
          }

  @doc """
  Creates a client struct that holds configuration and parsed HGT files.

  If the directory at the given `path` doesn't exist, creates it.

  ## Options

  The supported options are:

  * `:source` - a SRTM source provifder (defaults to
    [USGS](https://dds.cr.usgs.gov/srtm/version2_1/))

  ## Examples

      iex> SRTM.Client.new("./cache")
      {:ok, %SRTM.Client{}}

  """
  @spec new(path :: Path.t(), opts :: list) :: {:ok, t} | {:error, error :: Error.t()}
  def new(path, opts \\ []) do
    source = Keyword.get(opts, :source, SRTM.Source.USGS)
    path = Path.expand(path)

    with :ok <- create_dir_if_not_exists(path) do
      middleware = [
        {Tesla.Middleware.Headers, [{"user-agent", "github.com/adriankumpf/srtm"}]}
      ]

      client = Tesla.client(middleware, {Tesla.Adapter.Hackney, recv_timeout: 30_000})

      {:ok, %__MODULE__{client: client, cache_path: path, data_cells: %{}, source: source}}
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
  def get_elevation(%Client{} = client, latitude, longitude)
      when -56 <= latitude and latitude <= 60 do
    with {:ok, %DataCell{} = dc, %Client{} = client} <- get_data_cell(client, latitude, longitude) do
      {:ok, DataCell.get_elevation(dc, latitude, longitude), client}
    end
  end

  def get_elevation(%Client{} = client, _latitude, _longitude) do
    {:ok, nil, client}
  end

  defp get_data_cell(%Client{data_cells: data_cells} = client, latitude, longitude) do
    cell_lat = floor(latitude)
    cell_lng = floor(longitude)

    with {:ok, data_cell} <- load_cell({cell_lat, cell_lng}, client) do
      data_cell = %DataCell{data_cell | last_used: DateTime.utc_now()}
      data_cells = Map.put(data_cells, {cell_lat, cell_lng}, {:ok, data_cell})
      {:ok, data_cell, %Client{client | data_cells: data_cells}}
    end
  end

  defp load_cell({lat, lng}, %Client{data_cells: data_cells, source: source} = client) do
    Map.get_lazy(data_cells, {lat, lng}, fn ->
      cell_name = to_cell_name(lat, lng)
      hgt_file_path = Path.join([client.cache_path, cell_name <> ".hgt"])

      if File.exists?(hgt_file_path) do
        DataCell.from_file(hgt_file_path)
      else
        with {:ok, ^hgt_file_path} <- source.fetch(client.client, client.cache_path, cell_name) do
          DataCell.from_file(hgt_file_path)
        end
      end
    end)
  end

  defp order_by_date_desc(d0, d1) do
    case DateTime.compare(d0, d1) do
      :gt -> true
      _ -> false
    end
  end

  defp to_cell_name(lat, lng) do
    if(lat >= 0, do: "N", else: "S") <>
      (lat |> floor() |> abs() |> pad(2)) <>
      if(lng >= 0, do: "E", else: "W") <>
      (lng |> floor() |> abs() |> pad(3))
  end

  defp pad(num, count) do
    num |> Integer.to_string() |> String.pad_leading(count, "0")
  end

  defp create_dir_if_not_exists(dir) do
    if File.exists?(dir) do
      with {:error, reason} <- File.mkdir_p(dir) do
        {:error,
         %Error{
           reason: :io_error,
           message: "Creation of the directory #{dir} failed: #{inspect(reason)}"
         }}
      end
    else
      :ok
    end
  end
end
