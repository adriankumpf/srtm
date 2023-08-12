defmodule SRTM.Source.Cache do
  @moduledoc false

  use SRTM.Source

  alias SRTM.Client

  @impl true
  def fetch(%Client{cache_path: cache_path}, {lat, lng}) do
    hgt_path = Path.join([cache_path, name(lat, lng) <> ".hgt"])

    if File.exists?(hgt_path) do
      {:ok, hgt_path}
    else
      {:error, :not_loaded}
    end
  end
end
