defmodule SRTMTest do
  use SRTM.Case, async: true

  @tag :integration
  test "gets elevation data" do
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

  defmodule TimeoutSource do
    use SRTM.Source

    @impl true
    def fetch(%SRTM.Client{}, {_lat, _lng}, _opts) do
      {:error, %SRTM.Error{reason: :timeout}}
    end
  end

  defmodule ErrorSource do
    use SRTM.Source

    @impl true
    def fetch(%SRTM.Client{}, {_lat, _lng}, _opts) do
      raise "This should not happen!"
    end
  end

  @sources [SRTM.Source.AWS]
  test "gets the elevation from the AWS dataset", %{bypass: bypass, client: client} do
    expect_hgt_download(bypass)

    assert {:ok, -51, _client} = SRTM.get_elevation(client, 36.455556, -116.866667)
  end

  @sources [SRTM.Source.ESA]
  test "gets the elevation from the ESA dataset", %{bypass: bypass, client: client} do
    expect_hgt_download(bypass)

    assert {:ok, -51, _client} = SRTM.get_elevation(client, 36.455556, -116.866667)
  end

  @sources [SRTM.Source.ESA]
  test "returns nil if the source returns :out_of_bounds error", %{client: client} do
    assert {:ok, nil, _client} = SRTM.get_elevation(client, 61, 0)
  end

  @sources [TimeoutSource]
  test "fails if no source could download a dataset file", %{client: client} do
    assert {:error, %SRTM.Error{reason: :timeout}} =
             SRTM.get_elevation(client, 36.455556, -116.866667)
  end

  @sources [TimeoutSource, SRTM.Source.AWS, SRTM.Source.ESA, ErrorSource]
  test "tries until a source succeeds", %{bypass: bypass, client: client} do
    bypass
    |> expect_hgt_download({503, "error"})
    |> expect_hgt_download()

    assert {:ok, -51, _client} = SRTM.get_elevation(client, 36.455556, -116.866667)
  end

  @sources []
  test "looks up file from the cache if no sources are configured", %{client: client} do
    assert {:error, %SRTM.Error{reason: :not_cached}} =
             SRTM.get_elevation(client, 36.455556, -116.866667)
  end

  for source <- [SRTM.Source.AWS, SRTM.Source.ESA] do
    @sources [source]
    test "caches HGT files from (source: #{source})", %{bypass: bypass, client: client} do
      expect_hgt_download(bypass)

      assert {:ok, -51, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
      assert {:ok, -51, _client} = SRTM.get_elevation(client, 36.455556, -116.866667)
    end
  end
end
