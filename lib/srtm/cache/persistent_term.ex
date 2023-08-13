defmodule SRTM.Cache.PersistentTerm do
  @moduledoc """
  The built-in in-memory cache backed by `:persistent_term`.

  When the cache is deleted (using `purge/0`) or data is inserted, a global garbage collection is
  initiated. It works like this:

  - All processes in the system will be scheduled to run a scan of their heaps for the cache that
  has been deleted/updated. While such scan is relatively light-weight, **if there are many
  processes, the system can become less responsive until all processes have scanned their heaps**.

  - If the deleted/updated cache (or any part of it) is still used by a process, that process will
  do a **major (fullsweep) garbage collection** and copy the term into the process. However, at most
  two processes at a time will be scheduled to do that kind of garbage collection.

  See the [persistent_term docs](https://www.erlang.org/doc/man/persistent_term) for further information.
  """

  @behaviour SRTM.Cache

  @cache __MODULE__

  @impl true
  def fetch(id) do
    data_cells = :persistent_term.get(@cache, %{})
    Map.fetch(data_cells, id)
  end

  @impl true
  def store(id, data_cell) do
    data_cells = :persistent_term.get(@cache, %{})
    :persistent_term.put(@cache, Map.put(data_cells, id, data_cell))
  end

  @doc """
  Removes parsed HGT files from the in-memory cache.

  ## Examples

      iex> SRTM.Cache.PersistentTerm.purge()
      :ok

  """
  @spec purge :: :ok
  def purge do
    :persistent_term.erase(@cache)
    :ok
  end
end
