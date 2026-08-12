defmodule SRTM.Source.AWS do
  @endpoint "https://s3.amazonaws.com/elevation-tiles-prod/skadi"

  @moduledoc """
  The built-in source for the [Terrain Tiles dataset](https://registry.opendata.aws/terrain-tiles/)
  hosted in Open Data Registry on AWS.

  ## Options

  - `:endpoint` (`t:String.t/0`) - the base URL of the dataset. Defaults to `#{@endpoint}`.

  - `:timeout` (`t:timeout/0`) - see `SRTM.Source.get/2`.

  """

  use SRTM.Source

  alias SRTM.Error

  @doc false
  @impl true
  def fetch(<<dir::binary-size(3)>> <> _ = hgt_name, opts) do
    opts = Keyword.validate!(opts, [:timeout, endpoint: @endpoint])

    with {:ok, gzipped_data} <- get("#{opts[:endpoint]}/#{dir}/#{hgt_name}.hgt.gz", opts) do
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
