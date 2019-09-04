defmodule SRTM.Source.ESA do
  use SRTM.Source
  @moduledoc false

  alias SRTM.Client

  @impl true
  def fetch(%Client{}, {lat, _lng}) when not (-56 < lat and lat < 60) do
    {:error, :out_of_bounds}
  end

  def fetch(%Client{client: client, cache_path: cache_path}, {lat, lng}) do
    url = "http://step.esa.int/auxdata/dem/SRTMGL1/#{name(lat, lng)}.SRTMGL1.hgt.zip"

    with {:ok, zipped_data} <- get(client, url),
         {:ok, [hgt_file]} <- unzip(zipped_data, cwd: cache_path) do
      {:ok, hgt_file}
    end
  end
end
