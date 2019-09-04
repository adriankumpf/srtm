defmodule SRTMTest do
  use ExUnit.Case
  # doctest SRTM

  test "gets elevation data from USGS" do
    {:ok, client} = SRTM.Client.new("./cache")

    assert {:ok, -51, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
    assert {:ok, 246, client} = SRTM.get_elevation(client, 45.2775, 13.726111)
    assert {:ok, 301, client} = SRTM.get_elevation(client, -26.4, 146.25)
    assert {:ok, 133, client} = SRTM.get_elevation(client, -12.1, -77.016667)
    assert {:ok, 1298, client} = SRTM.get_elevation(client, 40.75, -111.883333)
    assert {:ok, 60, client} = SRTM.get_elevation(client, -55.948666, -67.275368)

    {:ok, client} = SRTM.Client.purge_in_memory_cache(client, keep: 1)

    assert {:ok, 1298, _client} = SRTM.get_elevation(client, 40.75, -111.883333)
  end

  test "gets elevation data from ESA" do
    {:ok, client} = SRTM.Client.new("./cache_new", source: SRTM.Source.ESA)

    assert {:ok, -51, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
    assert {:ok, 239, client} = SRTM.get_elevation(client, 45.2775, 13.726111)
    assert {:ok, 299, client} = SRTM.get_elevation(client, -26.4, 146.25)
    assert {:ok, 133, client} = SRTM.get_elevation(client, -12.1, -77.016667)
    assert {:ok, 1298, client} = SRTM.get_elevation(client, 40.75, -111.883333)
    assert {:ok, 61, client} = SRTM.get_elevation(client, -55.948666, -67.275368)

    {:ok, client} = SRTM.Client.purge_in_memory_cache(client, keep: 1)

    assert {:ok, 1298, _client} = SRTM.get_elevation(client, 40.75, -111.883333)
  end

  test "checks bounds [USGS]" do
    {:ok, client} = SRTM.Client.new("./cache")

    assert {:ok, nil, client} = SRTM.get_elevation(client, 65.011237, 25.484176)
    assert {:ok, nil, client} = SRTM.get_elevation(client, -63.359899, -57.331874)
    assert {:ok, nil, client} = SRTM.get_elevation(client, -56.359899, -57.331874)
  end

  test "checks bounds [ESA]" do
    {:ok, client} = SRTM.Client.new("./cache_new", source: SRTM.Source.ESA)

    assert {:ok, nil, client} = SRTM.get_elevation(client, 60.259915, 24.977134)
    assert {:ok, nil, client} = SRTM.get_elevation(client, -56.359899, -57.331874)
  end
end
