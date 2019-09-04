defmodule SRTM.Source.ESA do
  @behaviour SRTM.Source
  @moduledoc false

  alias SRTM.Error

  @impl true
  def fetch(%Tesla.Client{} = client, path, name) do
    url = "http://step.esa.int/auxdata/dem/SRTMGL1/#{name}.SRTMGL1.hgt.zip"

    with {:ok, zipped_data} <- get(client, url),
         {:ok, [hgt_file]} <- unzip(zipped_data, cwd: path) do
      {:ok, hgt_file}
    end
  end

  defp get(client, url) do
    case Tesla.get(client, url) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        {:error,
         %Error{
           reason: :download_failed,
           message: "HGT file download failed: #{status} – #{body}"
         }}

      {:error, reason} ->
        {:error, %Error{reason: reason, message: "HTTP request failed"}}
    end
  end

  defp unzip(zipped_binary, opts) do
    with {:error, reason} <- :zip.unzip(zipped_binary, opts) do
      {:error,
       %Error{reason: :io_error, message: "Unzipping HGT file failed: #{inspect(reason)}"}}
    end
  end
end
