defmodule SRTMTest do
  use ExUnit.Case

  test "gets elevation data from USGS" do
    {:ok, client} = SRTM.Client.new("./.srtm_cache")

    assert {:ok, -51, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
    assert {:ok, 239, client} = SRTM.get_elevation(client, 45.2775, 13.726111)
    assert {:ok, 299, client} = SRTM.get_elevation(client, -26.4, 146.25)
    assert {:ok, 133, client} = SRTM.get_elevation(client, -12.1, -77.016667)
    assert {:ok, 1294, client} = SRTM.get_elevation(client, 40.75, -111.883333)
    assert {:ok, 61, client} = SRTM.get_elevation(client, -55.948666, -67.275368)
    assert {:ok, 24, client} = SRTM.get_elevation(client, 60.259915, 24.977134)
    assert {:ok, 112, client} = SRTM.get_elevation(client, 64.351085, 26.273660)
    assert {:ok, 14, client} = SRTM.get_elevation(client, 65.011237, 25.484176)
    assert {:ok, 203, client} = SRTM.get_elevation(client, -63.359899, -57.331874)
    assert {:ok, nil, client} = SRTM.get_elevation(client, -56.359899, -57.331874)
    assert {:ok, nil, client} = SRTM.get_elevation(client, -56.359899, -57.331874)
    assert {:ok, nil, client} = SRTM.get_elevation(client, 89.559011, 97.407534)
    assert {:ok, 2435, client} = SRTM.get_elevation(client, -83.755023, 3.016760)
    assert {:ok, 368, client} = SRTM.get_elevation(client, -48.954253, 68.990165)
    assert {:ok, nil, client} = SRTM.get_elevation(client, 2.984654, 59.686144)

    {:ok, client} = SRTM.Client.purge_in_memory_cache(client, keep: 1)

    assert {:ok, 1294, _client} = SRTM.get_elevation(client, 40.75, -111.883333)
  end
end
