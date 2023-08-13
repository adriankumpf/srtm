defmodule SRTMTest do
  use SRTM.Case, async: true

  @tag :integration
  test "gets elevation data" do
    assert {:ok, -51} = SRTM.get_elevation(36.455556, -116.866667)
    assert {:ok, 239} = SRTM.get_elevation(45.2775, 13.726111)
    assert {:ok, 299} = SRTM.get_elevation(-26.4, 146.25)
    assert {:ok, 133} = SRTM.get_elevation(-12.1, -77.016667)
    assert {:ok, 1294} = SRTM.get_elevation(40.75, -111.883333)
    assert {:ok, 61} = SRTM.get_elevation(-55.948666, -67.275368)
    assert {:ok, 24} = SRTM.get_elevation(60.259915, 24.977134)
    assert {:ok, 112} = SRTM.get_elevation(64.351085, 26.273660)
    assert {:ok, 14} = SRTM.get_elevation(65.011237, 25.484176)
    assert {:ok, 203} = SRTM.get_elevation(-63.359899, -57.331874)
    assert {:ok, nil} = SRTM.get_elevation(-56.359899, -57.331874)
    assert {:ok, nil} = SRTM.get_elevation(-56.359899, -57.331874)
    assert {:ok, nil} = SRTM.get_elevation(89.559011, 97.407534)
    assert {:ok, 2435} = SRTM.get_elevation(-83.755023, 3.016760)
    assert {:ok, 368} = SRTM.get_elevation(-48.954253, 68.990165)
    assert {:ok, nil} = SRTM.get_elevation(2.984654, 59.686144)

    assert {:ok, 1294} = SRTM.get_elevation(40.75, -111.883333)
  end

  defmodule TimeoutSource do
    use SRTM.Source

    @impl true
    def fetch(_hgt_name, _opts) do
      {:error, %SRTM.Error{reason: :timeout}}
    end
  end

  defmodule ErrorSource do
    use SRTM.Source

    @impl true
    def fetch(_hgt_name, _opts) do
      raise "This should not happen!"
    end
  end

  @lat 36.455556
  @lng -116.866667

  @sources [SRTM.Source.AWS]
  test "gets the elevation from the AWS dataset", %{bypass: bypass, opts: opts} do
    expect_hgt_download(bypass)

    assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
  end

  @sources [SRTM.Source.ESA]
  test "gets the elevation from the ESA dataset", %{bypass: bypass, opts: opts} do
    expect_hgt_download(bypass)

    assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
  end

  @sources [TimeoutSource]
  test "fails if no source could download a dataset file", %{opts: opts} do
    assert {:error, %SRTM.Error{reason: :timeout}} = SRTM.get_elevation(@lat, @lng, opts)
  end

  @sources [TimeoutSource, SRTM.Source.AWS, SRTM.Source.ESA, ErrorSource]
  test "tries until a source succeeds", %{bypass: bypass, opts: opts} do
    bypass
    |> expect_hgt_download({503, "error"})
    |> expect_hgt_download()

    assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
  end

  @sources []
  test "attempts to look up file from the cache if no sources are configured", %{opts: opts} do
    assert {:error, %SRTM.Error{reason: :missing_sources}} =
             SRTM.get_elevation(@lat, @lng, opts)
  end

  for source <- [SRTM.Source.AWS, SRTM.Source.ESA] do
    @sources [source]
    test "caches HGT files from (source: #{source})", %{bypass: bypass, opts: opts} do
      expect_hgt_download(bypass)

      assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
      assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, Keyword.merge(opts, sources: []))
    end
  end

  @sources [SRTM.Source.AWS]
  test "populates higher caches", %{bypass: bypass, opts: opts} do
    expect_hgt_download(bypass)

    for opts <- [
          Keyword.merge(opts, in_memory_cache_enabled: false),
          Keyword.merge(opts, sources: [], in_memory_cache_enabled: false),
          Keyword.merge(opts, sources: []),
          Keyword.merge(opts, sources: [], disk_cache_enabled: false)
        ] do
      assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
    end
  end
end
