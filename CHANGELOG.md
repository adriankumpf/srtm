# Changelog

## v0.8.0 (2023-08-14)

### Breaking Changes

- Remove `SRTM.Client`
- Remove `SRTM.Client.purge_in_memory_cache/2`
- Add in-memory cache backend by `:persistent_term`
- Add `:disk_cache_enabled`, `:disk_cache_path`, `:in_memory_cache_enabled` and `:in_memory_cache_module` options to `SRTM.get_elevation/3`

## v0.7.0 (2023-08-13)

### Breaking Changes

- Require Elixir 1.11
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
