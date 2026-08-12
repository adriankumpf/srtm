defmodule SRTM.Cache.PersistentTerm do
  @moduledoc """
  The built-in in-memory cache backed by `:persistent_term`.

  Every HGT file is stored under its own key, so adding one neither rewrites the rest of the cache
  nor triggers a global garbage collection. Erasing a key does, and `purge/0` erases one per cached
  file:

  - All processes in the system will be scheduled to run a scan of their heaps for the term that
  has been erased. While such scan is relatively light-weight, **if there are many processes, the
  system can become less responsive until all processes have scanned their heaps**.

  - If the erased term is still used by a process, that process will do a **major (fullsweep)
  garbage collection** and copy the term into the process. However, at most two processes at a time
  will be scheduled to do that kind of garbage collection.

  See the [persistent_term docs](https://www.erlang.org/doc/man/persistent_term) for further information.
  """

  @behaviour SRTM.Cache

  @impl true
  def fetch(id) do
    case :persistent_term.get({__MODULE__, id}, :error) do
      :error -> :error
      data_cell -> {:ok, data_cell}
    end
  end

  @impl true
  def store(id, data_cell) do
    :persistent_term.put({__MODULE__, id}, data_cell)
  end

  @doc """
  Removes parsed HGT files from the in-memory cache.

  ## Examples

      iex> SRTM.Cache.PersistentTerm.purge()
      :ok

  """
  @spec purge :: :ok
  def purge do
    for {{__MODULE__, _id} = key, _data_cell} <- :persistent_term.get() do
      :persistent_term.erase(key)
    end

    :ok
  end
end
