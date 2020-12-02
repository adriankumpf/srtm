# SRTM

![Hex.pm](https://img.shields.io/hexpm/v/srtm)

<!-- MDOC !-->

SRTM is a small library that provides a simple interface to query locations on
the earth for elevation data from the NASA Shuttle Radar Topography Mission
(SRTM).

## Examples

```elixir
{:ok, client} = SRTM.Client.new("./cache")
#=> {:ok, %SRTM.Client{}}

{:ok, elevation, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
#=> {:ok, -51, %SRTM.Client{}}
```

<!-- MDOC !-->

See the [documentation](https://hexdocs.pm/srtm) for further
information on configuration.

## Installation

Add `srtm` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:srtm, "~> 0.5"},
    {:hackney, "~> 1.15"}
  ]
end
```

By default, `srtm` uses [hackney](https://github.com/benoitc/hackney) (via `Tesla.Adapter.Hackney`). Add `hackney` to the list of dependencies too if you don't want to use another HTTP adapter (see [Tesla Adapters](https://github.com/teamon/tesla#adapters) to find all available adapters and [`SRTM.Client.new/1`](https://hexdocs.pm/discovergy/Discovergy.Client.html#new/1) on how to configure another adapter).
