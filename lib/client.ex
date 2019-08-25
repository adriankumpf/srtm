defmodule SRTM.Client do
  @moduledoc """
  This module is the client for querying elevation data.

  It caches SRTM files on disk.

  Note: Files are loaded into memory! Querying many coordinates at different
  locations on Earth will consume quite a bit of memory.
  """

  alias __MODULE__, as: Client
  alias SRTM.DataCell

  defstruct [:client, :cache_path, :data_cells, :source]

  @doc """
  Create a client for querying elevation data. It takes a path

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

    data_cells =
      cache_path
      |> File.ls!()
      |> Enum.map(&Path.join(path, &1))
      |> Enum.map(&DataCell.from_file!/1)

    %__MODULE__{client: client, cache_path: cache_path, data_cells: data_cells, source: source}
  end

  def get_elevation(%Client{} = client, latitude, longitude) do
    with {:ok, %DataCell{} = dc, %Client{} = client} <- get_data_cell(client, latitude, longitude) do
      {:ok, DataCell.get_elevation(dc, latitude, longitude), client}
    end
  end

  defp get_data_cell(%Client{data_cells: data_cells} = client, latitude, longitude) do
    cell_lat = floor(latitude)
    cell_lng = floor(longitude)

    data_cell =
      Enum.find(data_cells, fn %DataCell{} = dc ->
        dc.latitude == cell_lat and dc.longitude == cell_lng
      end)

    case data_cell do
      %DataCell{} = data_cell -> {:ok, data_cell, client}
      nil -> download_cell(client, latitude, longitude)
    end
  end

  defp download_cell(%Client{source: source} = client, latitude, longitude) do
    name = to_cell_name(latitude, longitude)

    with {:ok, hgt_file} <- source.fetch(client.client, client.cache_path, name),
         data_cell = DataCell.from_file!(hgt_file) do
      {:ok, data_cell, %Client{client | data_cells: [data_cell | client.data_cells]}}
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
end
