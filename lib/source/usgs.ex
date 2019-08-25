defmodule SRTM.Source.USGS do
  @behaviour SRTM.Source
  @moduledoc false

  @list "./priv/list.json"
        |> File.read!()
        |> Jason.decode!()

  @impl true
  def fetch(%Tesla.Client{} = client, path, name) do
    url =
      with nil <- get_in(@list, ["srtm1", name <> ".hgt"]),
           nil <- get_in(@list, ["srtm3", name <> ".hgt"]) do
        raise("file not found: #{name}")
      end

    with {:ok, zipped_data} <- get(client, url),
         {:ok, [hgt_file]} <- :zip.unzip(zipped_data, cwd: path) do
      {:ok, hgt_file}
    end
  end

  defp get(client, url) do
    case Tesla.get(client, url) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
      {:ok, %Tesla.Env{}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end
end
