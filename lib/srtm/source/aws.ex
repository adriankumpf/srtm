defmodule SRTM.Source.AWS do
  @moduledoc """
  The built-in source for the [Terrain Tiles dataset](https://registry.opendata.aws/terrain-tiles/)
  hosted in Open Data Registry on AWS.
  """

  use SRTM.Source

  alias SRTM.Error

  @endpoint "https://s3.amazonaws.com/elevation-tiles-prod/skadi"

  @doc false
  @impl true
  def fetch(<<dir::binary-size(3)>> <> _ = hgt_name, opts) do
    endpoint = opts[:endpoint] || @endpoint

    with {:ok, gzipped_data} <- get("#{endpoint}/#{dir}/#{hgt_name}.hgt.gz", opts) do
      gunzip(gzipped_data)
    end
  end

  # A 200 response is not necessarily an archive: a captive portal or a proxy can serve HTML
  # instead. Returning an error rather than raising lets the next source take over.
  defp gunzip(gzipped_data) do
    {:ok, :zlib.gunzip(gzipped_data)}
  rescue
    ErlangError ->
      {:error, %Error{reason: :invalid_archive, message: "Gunzipping the HGT file failed"}}
  end
end
