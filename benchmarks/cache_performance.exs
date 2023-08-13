coordinates =
  1..100
  |> Stream.zip(Stream.cycle(-10..10))
  |> Stream.map(fn {lat, lng} -> {34 + lat / 10_000, 20.435 + lng} end)
  |> Enum.shuffle()

# Download files
for {lat, lng} <- coordinates do
  {:ok, _elevation} = SRTM.get_elevation(lat, lng)
end

Benchee.run(
  %{
    "file cache" => fn ->
      Enum.map(coordinates, fn {lat, lng} ->
        {:ok, elevation} = SRTM.get_elevation(lat, lng, caches: [SRTM.Cache.File], sources: [])
        elevation
      end)
    end,
    "in-memory cache" => fn ->
      Enum.map(coordinates, fn {lat, lng} ->
        {:ok, elevation} = SRTM.get_elevation(lat, lng, sources: [])
        elevation
      end)
    end
  },
  warmup: 1,
  time: 2,
  memory_time: 2
)
