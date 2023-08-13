defmodule SRTM.Source.ESA do
  @moduledoc """
  The built-in source for the SRTMGL1 dataset hosted on
  [esa.int](http://step.esa.int/auxdata/dem/SRTMGL1/).
  """

  use SRTM.Source

  alias SRTM.Error

  @endpoint "http://step.esa.int/auxdata/dem/SRTMGL1"

  @impl true
  def fetch(hgt_name, opts) do
    endpoint = opts[:endpoint] || @endpoint

    with {:ok, zipped_data} <- get("#{endpoint}/#{hgt_name}.SRTMGL1.hgt.zip"),
         {:ok, data} <- unzip(zipped_data) do
      {:ok, data}
    end
  end

  defp unzip(zipped_binary) do
    case :zip.unzip(zipped_binary, [:memory]) do
      {:ok, [{_filename, data}]} ->
        {:ok, data}

      {:error, reason} ->
        message = "Unzipping HGT file failed: #{inspect(reason)}"
        {:error, %Error{reason: :io_error, message: message}}
    end
  end
end
