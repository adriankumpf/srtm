defmodule SRTM.Source.ESA do
  @endpoint "https://step.esa.int/auxdata/dem/SRTMGL1"

  @moduledoc """
  The built-in source for the SRTMGL1 dataset hosted on
  [esa.int](https://step.esa.int/auxdata/dem/SRTMGL1/).

  These are the raw SRTMGL1 tiles: they span 60°N to 56°S, the extent of the shuttle's orbit, and
  there are none over open water. Lookups outside that coverage fail with a `:download_failed`
  error, so this source works best behind one that covers the whole globe, such as
  `SRTM.Source.AWS`.

  ## Options

  - `:endpoint` (`t:String.t/0`) - the base URL of the dataset. Defaults to `#{@endpoint}`.

  - `:timeout` (`t:timeout/0`) - see `SRTM.Source.get/2`.

  """

  use SRTM.Source

  alias SRTM.Error

  @doc false
  @impl true
  def fetch(hgt_name, opts) do
    opts = Keyword.validate!(opts, [:timeout, endpoint: @endpoint])

    with {:ok, zipped_data} <- get("#{opts[:endpoint]}/#{hgt_name}.SRTMGL1.hgt.zip", opts) do
      unzip(zipped_data)
    end
  end

  # A 200 response is not necessarily an archive: a captive portal or a proxy can serve HTML
  # instead. Reporting that as an error rather than crashing lets the next source take over.
  defp unzip(zipped_binary) do
    case :zip.unzip(zipped_binary, [:memory]) do
      {:ok, [{_filename, data}]} ->
        {:ok, data}

      {:ok, entries} ->
        message = "Expected exactly one file in the archive, got #{length(entries)}"
        {:error, %Error{reason: :invalid_archive, message: message}}

      {:error, reason} ->
        message = "Unzipping the HGT file failed: #{inspect(reason)}"
        {:error, %Error{reason: :invalid_archive, message: message}}
    end
  end
end
