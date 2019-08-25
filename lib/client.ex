defmodule Srtm.Client do
  alias __MODULE__, as: Client
  alias Srtm.DataCell

  defstruct [:client, :cache_path, :data_cells, :source]

  def new(path, opts \\ []) do
    source = Keyword.get(opts, :source, Srtm.Source.USGS)

    cache_path = Path.expand(path)

    if not File.dir?(cache_path) do
      raise "directory does not exist: #{cache_path}"
    end

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
    cell_lat = latitude |> floor() |> abs()
    cell_lng = longitude |> floor() |> abs()

    data_cell =
      Enum.find(data_cells, fn %DataCell{} = dc ->
        dc.latitude == cell_lat and dc.longitude == cell_lng
      end)

    case data_cell do
      %DataCell{} = data_cell ->
        {:ok, data_cell, client}

      nil ->
        name = to_cell_name(latitude, longitude)
        download_cell(client, name)
    end
  end

  defp download_cell(%Client{source: source} = client, name) do
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
