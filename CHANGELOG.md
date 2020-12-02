# Changelog

## v0.6.0 (2020-12-02)

### Breaking Changes

- Use `Tesla.Adapter.Hackney` as default adapter. Add `hackney` to the list of dependencies if you don't want to use another HTTP adapter (see [Tesla Adapters](https://github.com/teamon/tesla#adapters) to find all available adapters and [`SRTM.Client.new/1`](https://hexdocs.pm/discovergy/Discovergy.Client.html#new/1) on how to configure another adapter).

  ```elixir
  def deps do
    [
      {:srtm, "~> 0.6"},
      {:hackney, "~> 1.15"}
    ]
  end
  ```
