defmodule SrtmTest do
  use ExUnit.Case
  # doctest Srtm

  test "greets the world" do
    client = Srtm.Client.new("./cache")

    assert {:ok, -51, _} = Srtm.get_elevation(client, 36.455556, -116.866667)
    assert {:ok, 246, _} = Srtm.get_elevation(client, 45.2775, 13.726111)
    assert {:ok, 301, _} = Srtm.get_elevation(client, -26.4, 146.25)
    assert {:ok, 133, _} = Srtm.get_elevation(client, -12.1, -77.016667)
    assert {:ok, 1298, _} = Srtm.get_elevation(client, 40.75, -111.883333)
  end
end
