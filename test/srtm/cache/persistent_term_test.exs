defmodule SRTM.Cache.PersistentTermTest do
  # Not async: `:persistent_term` is global and `purge/0` affects the whole VM.
  use ExUnit.Case, async: false

  alias SRTM.Cache.PersistentTerm

  setup do
    on_exit(&PersistentTerm.purge/0)

    %{data_cell: SRTM.Case.data_cell_fixture()}
  end

  test "stores and fetches data cells", %{data_cell: data_cell} do
    assert :error = PersistentTerm.fetch("N36W117.hgt")

    assert :ok = PersistentTerm.store("N36W117.hgt", data_cell)

    assert {:ok, ^data_cell} = PersistentTerm.fetch("N36W117.hgt")
  end

  test "purge/0 removes only its own entries", %{data_cell: data_cell} do
    :persistent_term.put(:unrelated_term, :keep_me)
    on_exit(fn -> :persistent_term.erase(:unrelated_term) end)

    :ok = PersistentTerm.store("N36W117.hgt", data_cell)
    :ok = PersistentTerm.store("N37W117.hgt", data_cell)

    assert :ok = PersistentTerm.purge()

    assert :error = PersistentTerm.fetch("N36W117.hgt")
    assert :error = PersistentTerm.fetch("N37W117.hgt")
    assert :keep_me = :persistent_term.get(:unrelated_term)
  end
end
