defmodule SRTM.Cache do
  @moduledoc """
  Specifies the API for using a custom Cache.

  The default caches are `SRTM.Cache.PersistentTerm` and `SRTM.Cache.File`.
  """

  alias SRTM.DataCell
  alias SRTM.Error

  @doc """
  For the given identifier, fetches a data cell from the cache.
  """
  @callback fetch(identifier :: Path.t()) :: {:ok, DataCell.t()} | :error

  @doc """
  Stores the given data cell in the cache.
  """
  @callback store(identifier :: Path.t(), data_cell :: DataCell.t()) :: :ok | {:error, Error.t()}
end
