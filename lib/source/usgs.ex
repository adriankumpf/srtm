defmodule SRTM.Source.USGS do
  @moduledoc false
  @behaviour SRTM.Source

  @list "./priv/list.json"
        |> File.read!()
        |> Jason.decode!()

  @impl true
  def fetch(%Tesla.Client{} = client, path, name) do
    url =
      with nil <- get_in(@list, ["srtm1", name <> ".hgt"]) do
        get_in(@list, ["srtm3", name <> ".hgt"])
      end

    if is_nil(url), do: raise("file not found: #{name}")

    result =
      case Tesla.get(client, url) do
        {:ok, %Tesla.Env{status: 200, body: body}} -> {:ok, body}
        {:ok, %Tesla.Env{}} -> {:error, :not_found}
        {:error, reason} -> {:error, reason}
      end

    with {:ok, zipped_data} <- result,
         {:ok, [hgt_file]} <- :zip.unzip(zipped_data, cwd: path) do
      {:ok, hgt_file}
    end
  end
end
