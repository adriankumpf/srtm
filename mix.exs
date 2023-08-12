defmodule SRTM.MixProject do
  use Mix.Project

  @version "0.6.0"
  @source_url "https://github.com/adriankumpf/srtm"

  def project do
    [
      app: :srtm,
      version: @version,
      elixir: "~> 1.9",
      name: "SRTM",
      description:
        "A small library that provides a simple interface to query locations on the earth for elevation data from the NASA Shuttle Radar Topography Mission (SRTM)",
      deps: deps(),
      package: package(),
      docs: [
        extras: ~w(CHANGELOG.md README.md),
        source_ref: "#{@version}",
        source_url: @source_url,
        main: "readme",
        groups_for_modules: [
          Sources: ~r/ Source/
        ],
        skip_undefined_reference_warnings_on: ~w(CHANGELOG.md README.md)
      ]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:tesla, "~> 1.3"},
      {:jason, "~> 1.1"},
      {:hackney, "~> 1.15", optional: true},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Adrian Kumpf"],
      links: %{"GitHub" => @source_url, "Changelog" => "#{@source_url}/blob/master/CHANGELOG.md"},
      files: ~w(lib mix.exs README.md LICENSE CHANGELOG.md)
    }
  end
end
