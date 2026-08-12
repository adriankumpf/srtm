defmodule SRTMTest do
  use SRTM.Case, async: true

  # Locations both datasets cover and agree on.
  @elevations [
    {36.455556, -116.866667, -51},
    {45.2775, 13.726111, 239},
    {-26.4, 146.25, 299},
    {-12.1, -77.016667, 133},
    {-55.948666, -67.275368, 61},
    {-48.954253, 68.990165, 368}
  ]

  # SRTMGL1 spans 60°N to 56°S and has no tiles over open water. Terrain Tiles fills those gaps from
  # other datasets, which also makes it disagree with the raw tiles in places: the two put Salt Lake
  # City at 1294 m and 1298 m respectively.
  @aws_elevations @elevations ++
                    [
                      {40.75, -111.883333, 1294},
                      {60.259915, 24.977134, 24},
                      {64.351085, 26.273660, 112},
                      {65.011237, 25.484176, 14},
                      {-63.359899, -57.331874, 203},
                      {-83.755023, 3.016760, 2435},
                      {-56.359899, -57.331874, nil},
                      {89.559011, 97.407534, nil},
                      {2.984654, 59.686144, nil}
                    ]

  @esa_elevations @elevations ++ [{40.75, -111.883333, 1298}]

  for {source, locations} <- [
        {SRTM.Source.AWS, @aws_elevations},
        {SRTM.Source.ESA, @esa_elevations}
      ] do
    @source source
    @locations locations

    @tag :integration
    test "gets elevation data from the live #{inspect(source)} dataset", %{opts: opts} do
      opts = Keyword.put(opts, :sources, [@source])

      for {latitude, longitude, elevation} <- @locations do
        assert SRTM.get_elevation(latitude, longitude, opts) == {:ok, elevation}
      end
    end
  end

  defmodule TimeoutSource do
    use SRTM.Source

    @impl true
    def fetch(_hgt_name, _opts) do
      {:error, %SRTM.Error{reason: :timeout, message: "timed out"}}
    end
  end

  defmodule ErrorSource do
    use SRTM.Source

    @impl true
    def fetch(_hgt_name, _opts) do
      raise "This should not happen!"
    end
  end

  defmodule FetchableTestCache do
    @behaviour SRTM.Cache

    @impl true
    def fetch(_id) do
      {:ok, SRTM.Case.data_cell_fixture()}
    end

    @impl true
    def store(_identifier, _data_cell) do
      raise "unimplemented!"
    end
  end

  defmodule StorableTestCache do
    @behaviour SRTM.Cache

    @impl true
    def fetch(_id) do
      :error
    end

    @impl true
    def store(identifier, data_cell) do
      send(:srtm_test, {:store, identifier, data_cell})
      :ok
    end
  end

  @lat 36.455556
  @lng -116.866667

  for source <- [SRTM.Source.AWS, SRTM.Source.ESA] do
    @sources [source]
    test "gets the elevation from the #{inspect(source)} dataset", %{bypass: bypass, opts: opts} do
      expect_hgt_download(bypass)

      assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
    end
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
  test "downloads on every lookup if all caches are disabled", %{bypass: bypass, opts: opts} do
    opts = Keyword.merge(opts, in_memory_cache_enabled: false, disk_cache_enabled: false)

    for _ <- 1..2 do
      expect_hgt_download(bypass)
      assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
    end

    refute File.exists?(Path.join(opts[:disk_cache_path], "N36W117.hgt"))
  end

  test "rejects unknown options" do
    assert_raise ArgumentError, ~r/:disc_cache_path/, fn ->
      SRTM.get_elevation(@lat, @lng, disc_cache_path: "/tmp")
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

  @sources [SRTM.Source.AWS]
  test "allows customizing the in-memory cache module", %{bypass: bypass, opts: opts} do
    Process.register(self(), :srtm_test)

    opts =
      Keyword.merge(opts,
        in_memory_cache_module: FetchableTestCache,
        disk_cache_enabled: false
      )

    assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)

    expect_hgt_download(bypass)

    opts =
      Keyword.merge(opts,
        in_memory_cache_module: StorableTestCache,
        disk_cache_enabled: false
      )

    assert {:ok, -51} = SRTM.get_elevation(@lat, @lng, opts)
    assert_received {:store, identifier, %SRTM.DataCell{}}
    assert "N36W117.hgt" == Path.basename(identifier)
  end
end
