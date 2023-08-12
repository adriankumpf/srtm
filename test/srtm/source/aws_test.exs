defmodule SRTM.Source.AWSTest do
  use SRTM.Case, async: true

  alias SRTM.Source.AWS

  test "downloads the HGT file into the cache",
       %{bypass: bypass, client: client, tmp_dir: tmp_dir} do
    expect_hgt_download(bypass)

    coors = {36.455556, -116.866667}
    assert {:ok, path} = AWS.fetch(client, coors, endpoint: "http://localhost:#{bypass.port}/")
    assert File.exists?(path)
    assert Path.dirname(path) == Path.absname(tmp_dir)
  end
end
