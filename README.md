# SRTM

[![CI](https://github.com/adriankumpf/srtm/actions/workflows/elixir.yml/badge.svg)](https://github.com/adriankumpf/srtm/actions/workflows/elixir.yml)
[![Docs](https://img.shields.io/badge/hex-docs-green.svg?style=flat)](https://hexdocs.pm/srtm)
[![Hex.pm](https://img.shields.io/hexpm/v/srtm?color=%23714a94)](http://hex.pm/packages/srtm)

A small library that provides a simple interface to query locations on the Earth for elevation data from the NASA Shuttle Radar Topography Mission (SRTM).

## Installation

Add `srtm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:srtm, "~> 0.8"},
  ]
end
```

## Examples

```elixir
iex> SRTM.get_elevation(36.455556, -116.866667)
{:ok, -51}
```

See the [documentation](https://hexdocs.pm/srtm) for further information on configuration.
