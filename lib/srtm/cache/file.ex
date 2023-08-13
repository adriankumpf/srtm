defmodule SRTM.Cache.File do
  @moduledoc """
  The built-in file cache.
  """

  @behaviour SRTM.Cache

  alias SRTM.DataCell
  alias SRTM.Error

  @impl true
  def fetch(path) do
    if File.exists?(path) do
      data = File.read!(path)
      name = Path.basename(path, ".hgt")
      DataCell.new(name, data)
    else
      :error
    end
  end

  @impl true
  def store(path, data_cell) do
    data = DataCell.to_binary(data_cell)

    cache_dir = Path.dirname(path)
    File.mkdir_p!(cache_dir)

    with {:error, reason} <- File.write(path, data) do
      message = "Writing hgt file '#{path}' failed: #{inspect(reason)}"
      {:error, %Error{reason: :io_error, message: message}}
    end
  end
end
