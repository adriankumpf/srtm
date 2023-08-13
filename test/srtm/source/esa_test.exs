defmodule SRTM.Source.ESATest do
  use SRTM.Case, async: true

  alias SRTM.Source.ESA

  test "downloads the HGT file into the cache", %{bypass: bypass} do
    expect_hgt_download(bypass)

    assert {:ok, <<5, 163, 5, 163, 5, 162, 5, 161, 5, 161>> <> _} =
             ESA.fetch("N36W117", endpoint: "http://localhost:#{bypass.port}/")
  end
end
