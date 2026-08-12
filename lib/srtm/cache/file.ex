defmodule SRTM.Cache.File do
  @moduledoc """
  The built-in file cache.
  """

  @behaviour SRTM.Cache

  alias SRTM.DataCell
  alias SRTM.Error

  @impl true
  def fetch(path) do
    with {:ok, data} <- File.read(path),
         {:ok, data_cell} <- DataCell.new(Path.basename(path, ".hgt"), data) do
      {:ok, data_cell}
    else
      {:error, _reason} -> :error
    end
  end

  @impl true
  def store(path, data_cell) do
    with :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, DataCell.to_binary(data_cell)) do
      :ok
    else
      {:error, reason} ->
        message = "Caching the HGT file at '#{path}' failed: #{inspect(reason)}"
        {:error, %Error{reason: :io_error, message: message}}
    end
  end
end
