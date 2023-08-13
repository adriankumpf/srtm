defmodule SRTM.Source.AWS do
  @moduledoc """
  The built-in source for the [Terrain Tiles dataset](https://registry.opendata.aws/terrain-tiles/)
  hosted in Open Data Registry on AWS.
  """

  use SRTM.Source

  @endpoint "https://s3.amazonaws.com/elevation-tiles-prod/skadi"

  @doc false
  @impl true
  def fetch(<<dir::binary-size(3)>> <> _ = hgt_name, opts) do
    endpoint = opts[:endpoint] || @endpoint

    with {:ok, zipped_data} <- get("#{endpoint}/#{dir}/#{hgt_name}.hgt.gz") do
      {:ok, :zlib.gunzip(zipped_data)}
    end
  end
end
