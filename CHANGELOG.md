# Changelog

## v0.7.0 (2023-08-13)

### Breaking Changes

- Require Elixir 1.10
- Remove USGS source
- Drop `:adapter` and `:opts` option from `SRTM.Client.new/1`

### Changes

- Replace hackney with httpc
- Update documentation
- Add CI workflow

## v0.6.0 (2020-12-02)

### Breaking Changes

- Use `Tesla.Adapter.Hackney` as default adapter. Add `hackney` to the list of dependencies if you don't want to use another HTTP adapter (see [Tesla Adapters](https://github.com/teamon/tesla#adapters) to find all available adapters and [`SRTM.Client.new/2`](https://hexdocs.pm/srtm/SRTM.Client.html#new/2) on how to configure another adapter).

  ```elixir
  def deps do
    [
      {:srtm, "~> 0.6"},
      {:hackney, "~> 1.15"}
    ]
  end
  ```
