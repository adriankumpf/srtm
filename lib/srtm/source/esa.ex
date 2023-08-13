defmodule SRTM.Source.ESA do
  @moduledoc """
  The built-in source for the SRTMGL1 dataset hosted on
  [esa.int](http://step.esa.int/auxdata/dem/SRTMGL1/).
  """

  use SRTM.Source

  alias SRTM.Client
  alias SRTM.Error

  @endpoint "http://step.esa.int/auxdata/dem/SRTMGL1"

  @impl true
  def fetch(%Client{}, {lat, _lng}, _opts) when not (-56 < lat and lat < 60) do
    {:error, :out_of_bounds}
  end

  def fetch(%Client{cache_path: cache_path}, {lat, lng}, opts) do
    endpoint = opts[:endpoint] || @endpoint

    with {:ok, zipped_data} <- get("#{endpoint}/#{name(lat, lng)}.SRTMGL1.hgt.zip"),
         {:ok, [hgt_file]} <- unzip(zipped_data, cwd: cache_path) do
      {:ok, hgt_file}
    end
  end

  defp unzip(zipped_binary, opts) do
    with {:error, reason} <- :zip.unzip(zipped_binary, opts) do
      {:error,
       %Error{reason: :io_error, message: "Unzipping HGT file failed: #{inspect(reason)}"}}
    end
  end
end
