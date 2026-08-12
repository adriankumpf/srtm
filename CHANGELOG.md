# Changelog

## Unreleased

### Breaking Changes

- Require Elixir 1.15 or later
- Unknown options now raise an `ArgumentError` instead of being silently ignored, both in
  `SRTM.get_elevation/3` and in the built-in sources
- Report a failed or unexpected archive as `:invalid_archive` instead of `:io_error`

### Changes

- Fetch the SRTMGL1 dataset in `SRTM.Source.ESA` over HTTPS instead of HTTP
- Disabling both caches no longer returns a `:missing_caches` error; every lookup downloads the HGT
  file instead
- Store each HGT file under its own `:persistent_term` key, so inserts no longer rewrite the whole
  cache or trigger a global garbage collection
- Pass source options through to the HTTP request, making `:timeout` usable via
  `sources: [{SRTM.Source.AWS, timeout: 5_000}]`
- Make `SRTM.DataCell.new/2` and `SRTM.DataCell.to_binary/1` public, so `SRTM.Cache`
  implementations can parse and serialize cached HGT files
- Make `SRTM.Source.get/2` public and document its `:timeout` option, along with the `:endpoint`
  option of `SRTM.Source.AWS` and `SRTM.Source.ESA`
- Return `:error` instead of raising when an HGT file in the disk cache can't be read
- Return an error instead of raising when a downloaded file isn't a readable archive, so the next
  source gets a turn

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
