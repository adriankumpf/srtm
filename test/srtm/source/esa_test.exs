defmodule SRTM.Source.ESATest do
  use SRTM.Case, async: true

  alias SRTM.Source.ESA

  test "downloads the HGT file into the cache",
       %{bypass: bypass, client: client, tmp_dir: tmp_dir} do
    expect_hgt_download(bypass)

    coords = {36.455556, -116.866667}

    assert {:ok, path} = ESA.fetch(client, coords, endpoint: "http://localhost:#{bypass.port}/")
    assert File.exists?(path)
    assert Path.dirname(path) == Path.absname(tmp_dir)
  end

  test "returns error if coordinates are out of bounds", %{bypass: bypass, client: client} do
    {lower_boundary, upper_boundary} = {-56, 60}

    for coords <- [{lower_boundary - 0.1, 12}, {upper_boundary + 0.1, 12}] do
      assert {:error, :out_of_bounds} =
               ESA.fetch(client, coords, endpoint: "http://localhost:#{bypass.port}/")
    end

    for coords <- [{lower_boundary + 0.1, 12}, {upper_boundary - 0.1, 12}] do
      expect_hgt_download(bypass, {404, ""})

      assert {:error, %SRTM.Error{reason: :download_failed}} =
               ESA.fetch(client, coords, endpoint: "http://localhost:#{bypass.port}/")
    end
  end
end
