defmodule SRTM.Source.AWS do
  @moduledoc """
  The built-in source for the [Terrain Tiles dataset](https://registry.opendata.aws/terrain-tiles/)
  hosted in Open Data Registry on AWS.
  """

  use SRTM.Source

  alias SRTM.Client
  alias SRTM.Error

  @endpoint "https://s3.amazonaws.com/elevation-tiles-prod/skadi"

  @doc false
  @impl true
  def fetch(%Client{cache_path: cache_path}, {lat, lng}, opts) do
    endpoint = opts[:endpoint] || @endpoint

    <<dir::binary-size(3)>> <> _ = name = name(lat, lng)
    url = "#{endpoint}/#{dir}/#{name}.hgt.gz"
    path = Path.join([cache_path, name <> ".hgt"])

    with {:ok, zipped_data} <- get(url),
         data = :zlib.gunzip(zipped_data),
         :ok <- write(path, data) do
      {:ok, path}
    end
  end

  defp write(path, data) do
    with {:error, reason} <- File.write(path, data) do
      {:error, %Error{reason: :io_error, message: "Writing hgt data failed: #{inspect(reason)}"}}
    end
  end
end
