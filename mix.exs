defmodule SRTM.MixProject do
  use Mix.Project

  @version "0.6.0"
  @source_url "https://github.com/adriankumpf/srtm"

  def project do
    [
      app: :srtm,
      version: @version,
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "SRTM",
      description:
        "A small library that provides a simple interface to query locations on the earth for elevation data from the NASA Shuttle Radar Topography Mission (SRTM)",
      deps: deps(),
      package: package(),
      docs: docs(),
      xref: [exclude: [CAStore]]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [extra_applications: [:inets, :ssl, :public_key]]
  end

  defp deps do
    [
      {:castore, "~> 1.0", optional: true},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:bypass, "~> 2.1", only: :test}
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

  defp docs do
    [
      extras: ~w(CHANGELOG.md README.md),
      source_ref: "#{@version}",
      source_url: @source_url,
      main: "readme",
      groups_for_modules: [
        Sources: ~r/Source/
      ],
      skip_undefined_reference_warnings_on: ~w(CHANGELOG.md README.md)
    ]
  end
end
