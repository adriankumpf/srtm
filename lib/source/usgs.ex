defmodule SRTM.Source.USGS do
  @behaviour SRTM.Source
  @moduledoc false

  alias SRTM.Error

  @list "./priv/list.json"
        |> File.read!()
        |> Jason.decode!()

  @impl true
  def fetch(%Tesla.Client{} = client, path, name) do
    with {:ok, url} <- find_url(name),
         {:ok, zipped_data} <- get(client, url),
         {:ok, [hgt_file]} <- unzip(zipped_data, cwd: path) do
      {:ok, hgt_file}
    end
  end

  defp find_url(name) do
    with nil <- get_in(@list, ["srtm1", name <> ".hgt"]),
         nil <- get_in(@list, ["srtm3", name <> ".hgt"]) do
      {:error, %Error{reason: :file_not_found, message: "Could not find HGT file: #{name}"}}
    else
      url when is_binary(url) -> {:ok, url}
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
       %Error{reason: :file_corrupt, message: "Unzipping HGT file failed: #{inspect(reason)}"}}
    end
  end
end
