defmodule SRTM.Source.ESATest do
  use SRTM.Case, async: true

  alias SRTM.Source.ESA

  test "downloads the HGT file into the cache", %{bypass: bypass} do
    expect_hgt_download(bypass)

    assert {:ok, <<5, 163, 5, 163, 5, 162, 5, 161, 5, 161>> <> _} =
             ESA.fetch("N36W117", endpoint: "http://localhost:#{bypass.port}/")
  end

  test "returns an error if the response isn't a zip archive", %{bypass: bypass} do
    expect_hgt_download(bypass, {200, "<html>captive portal</html>"})

    assert {:error, %SRTM.Error{reason: :invalid_archive}} =
             ESA.fetch("N36W117", endpoint: "http://localhost:#{bypass.port}/")
  end

  test "rejects unknown options" do
    assert_raise ArgumentError, ~r/:timout/, fn ->
      ESA.fetch("N36W117", timout: 5_000)
    end
  end
end
