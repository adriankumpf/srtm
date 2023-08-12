defmodule SRTM.Source.Cache do
  @moduledoc false

  use SRTM.Source

  alias SRTM.Client
  alias SRTM.Error

  @impl true
  def fetch(%Client{cache_path: cache_path}, {lat, lng}, _opts) do
    name = name(lat, lng) <> ".hgt"
    path = Path.join([cache_path, name])

    if File.exists?(path) do
      {:ok, path}
    else
      message = "Could not find the HGT file '#{name}' in the cache '#{cache_path}"
      {:error, %Error{reason: :not_cached, message: message}}
    end
  end
end
