# SRTM

[![CI](https://github.com/adriankumpf/srtm/actions/workflows/elixir.yml/badge.svg)](https://github.com/adriankumpf/srtm/actions/workflows/elixir.yml)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/srtm)
[![Hex.pm](https://img.shields.io/hexpm/v/srtm?color=%23714a94)](https://hex.pm/packages/srtm)

A small library that provides a simple interface to query locations on the Earth for elevation data from the NASA Shuttle Radar Topography Mission (SRTM).

## Installation

Add `srtm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:srtm, "~> 0.9"},
  ]
end
```

## Examples

```elixir
iex> SRTM.get_elevation(36.455556, -116.866667)
{:ok, -51}
```

Elevations are in meters. The lookup reads the sample the coordinate falls into rather than interpolating between the surrounding ones, so the answer describes a grid cell roughly 30 m across. Coordinates the dataset holds no measurement for — voids, and open water in the raw tiles — come back as `nil`:

```elixir
iex> SRTM.get_elevation(2.984654, 59.686144)
{:ok, nil}
```

## Caching

Elevation data ships as HGT files, each covering one degree of latitude and longitude and taking up about 25 MB. The first lookup inside a cell downloads its file; later ones are served from the caches.

**Downloaded files are written to `./srtm_cache` by default.** Point `:disk_cache_path` somewhere else, or turn the disk cache off to keep them out of the file system entirely:

```elixir
SRTM.get_elevation(36.455556, -116.866667, disk_cache_path: "/var/cache/srtm")
SRTM.get_elevation(36.455556, -116.866667, disk_cache_enabled: false)
```

Parsed files are kept in memory with `:persistent_term` as well, trading memory for lookup speed. Read [`SRTM.Cache.PersistentTerm`](https://hexdocs.pm/srtm/SRTM.Cache.PersistentTerm.html) before caching a large number of cells; its `purge/0` frees the memory again.

## Sources

Files are downloaded from [`SRTM.Source.AWS`](https://hexdocs.pm/srtm/SRTM.Source.AWS.html) and then [`SRTM.Source.ESA`](https://hexdocs.pm/srtm/SRTM.Source.ESA.html), in that order, until one succeeds. AWS serves the Terrain Tiles dataset, which covers the whole globe. ESA serves the raw SRTMGL1 tiles, which span 60°N to 56°S and omit open water, so it only works as a fallback behind a source with global coverage.

Sources and caches are both behaviours, so you can plug in your own — see [`SRTM.Source`](https://hexdocs.pm/srtm/SRTM.Source.html) and [`SRTM.Cache`](https://hexdocs.pm/srtm/SRTM.Cache.html).

See the [documentation](https://hexdocs.pm/srtm) for further information on configuration.

## License

MIT
