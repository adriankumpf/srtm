defmodule SRTM.MixProject do
  use Mix.Project

  @version "0.6.0"
  @github "https://github.com/adriankumpf/srtm"

  def project do
    [
      app: :srtm,
      version: @version,
      elixir: "~> 1.9",
      name: "SRTM",
      description:
        "A small library that provides a simple interface to query locations on the earth for elevation data from the NASA Shuttle Radar Topography Mission (SRTM)",
      deps: deps(),
      aliases: [docs: &build_docs/1],
      package: package()
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:tesla, "~> 1.3"},
      {:jason, "~> 1.1"},
      {:hackney, "~> 1.15", optional: true}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Adrian Kumpf"],
      links: %{"GitHub" => @github, "Changelog" => "#{@github}/blob/master/CHANGELOG.md"},
      files: ~w(lib data .formatter.exs mix.exs README* LICENSE*)
    }
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.path_for(:escripts), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["SRTM", @version, Mix.Project.compile_path()]
    opts = ~w[--main SRTM --source-ref v#{@version} --source-url #{@github}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
