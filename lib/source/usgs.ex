defmodule SRTM.Source.USGS do
  use SRTM.Source
  @moduledoc false

  alias SRTM.Client

  @list "./priv/list.json"
        |> File.read!()
        |> Jason.decode!()

  @impl true
  def fetch(%Client{}, {lat, _lng}) when not (-56 < lat and lat < 61) do
    {:error, :out_of_bounds}
  end

  def fetch(%Client{client: client, cache_path: cache_path}, {lat, lng}) do
    with {:ok, url} <- name(lat, lng) |> find_url(),
         {:ok, zipped_data} <- get(client, url),
         {:ok, [hgt_file]} <- unzip(zipped_data, cwd: cache_path) do
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

  defp unzip(zipped_binary, opts) do
    with {:error, reason} <- :zip.unzip(zipped_binary, opts) do
      {:error,
       %Error{reason: :io_error, message: "Unzipping HGT file failed: #{inspect(reason)}"}}
    end
  end
end
