defmodule SRTM.Source.AWSTest do
  use SRTM.Case, async: true

  alias SRTM.Source.AWS

  test "downloads the HGT file into the cache", %{bypass: bypass} do
    expect_hgt_download(bypass)

    assert {:ok, <<5, 161, 5, 160, 5, 159>> <> _} =
             AWS.fetch("N36W117", endpoint: "http://localhost:#{bypass.port}/")
  end
end
