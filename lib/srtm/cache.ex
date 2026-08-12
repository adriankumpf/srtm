defmodule SRTM.Cache do
  @moduledoc """
  Specifies the API for using a custom Cache.

  Caches are keyed by the path the disk cache would store the HGT file at, such as
  `./srtm_cache/N36W117.hgt`. `Path.basename(identifier, ".hgt")` recovers the name that
  `SRTM.DataCell.new/2` needs to parse one, and `SRTM.DataCell.to_binary/1` serializes one back.

  The default caches are `SRTM.Cache.PersistentTerm` and `SRTM.Cache.File`.

  ## Example

      defmodule MyApp.ETSCache do
        @behaviour SRTM.Cache

        @impl true
        def fetch(identifier) do
          hgt_name = Path.basename(identifier, ".hgt")

          with [{^identifier, hgt_data}] <- :ets.lookup(:srtm_tiles, identifier),
               {:ok, data_cell} <- SRTM.DataCell.new(hgt_name, hgt_data) do
            {:ok, data_cell}
          else
            _otherwise -> :error
          end
        end

        @impl true
        def store(identifier, data_cell) do
          :ets.insert(:srtm_tiles, {identifier, SRTM.DataCell.to_binary(data_cell)})
          :ok
        end
      end

  Pass it to `SRTM.get_elevation/3`:

      SRTM.get_elevation(36.455556, -116.866667, in_memory_cache_module: MyApp.ETSCache)

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
