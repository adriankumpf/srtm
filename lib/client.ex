defmodule SRTM.Client do
  @moduledoc """
  This module holds the client for querying elevation data.
  """

  alias __MODULE__, as: Client
  alias SRTM.DataCell

  defstruct [:client, :cache_path, :data_cells, :source]

  @doc """
  Creates a client struct.

  If the directory at the given `path` doesn't exist, creates it.

  ## Options

  The supported options are:

  * `:source` - a SRTM source provifder (defaults to
    [USGS](https://dds.cr.usgs.gov/srtm/version2_1/))

  ## Examples

      iex> SRTM.Client.new("./cache")
      %SRTM.Client{}

  """
  def new(path, opts \\ []) do
    source = Keyword.get(opts, :source, SRTM.Source.USGS)

    cache_path = Path.expand(path)
    if not File.dir?(cache_path), do: File.mkdir_p!(cache_path)

    middleware = [
      {Tesla.Middleware.Headers, [{"user-agent", "github.com/adriankumpf/srtm"}]}
    ]

    client = Tesla.client(middleware, {Tesla.Adapter.Hackney, recv_timeout: 30_000})

    %__MODULE__{client: client, cache_path: cache_path, data_cells: %{}, source: source}
  end

  @doc false
  def get_elevation(%Client{} = client, latitude, longitude) do
    with {:ok, %DataCell{} = dc, %Client{} = client} <- get_data_cell(client, latitude, longitude) do
      {:ok, DataCell.get_elevation(dc, latitude, longitude), client}
    end
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
        {:ok, DataCell.from_file!(hgt_file_path)}
      else
        with {:ok, ^hgt_file_path} <- source.fetch(client.client, client.cache_path, cell_name) do
          {:ok, DataCell.from_file!(hgt_file_path)}
        end
      end
    end)
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
end
