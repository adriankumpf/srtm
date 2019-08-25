defmodule Srtm.Source.USGS do
  @behaviour Srtm.Source

  @base "https://dds.cr.usgs.gov/srtm/version2_1/SRTM3"

  @continents [
    "Africa",
    "Australia",
    "Eurasia",
    "Islands",
    "North_America",
    "South_America"
  ]

  @impl true
  def fetch(%Tesla.Client{} = client, path, name) do
    result =
      Enum.reduce_while(@continents, {:error, :not_found}, fn continent, acc ->
        case Tesla.get(client, "#{@base}/#{continent}/#{name}.hgt.zip") do
          {:ok, %Tesla.Env{status: 200, body: body}} -> {:halt, {:ok, body}}
          {:ok, %Tesla.Env{status: 404}} -> {:cont, acc}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)

    with {:ok, zipped_data} <- result,
         {:ok, [hgt_file]} <- :zip.unzip(zipped_data, cwd: path) do
      {:ok, hgt_file}
    end
  end
end
