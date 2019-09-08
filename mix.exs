defmodule SRTM.MixProject do
  use Mix.Project

  @version "0.3.0"
  @url "https://github.com/adriankumpf/srtm"

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
      {:mint, "~> 0.4"},
      {:castore, "~> 0.1"},
      {:jason, "~> 1.1"}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Adrian Kumpf"],
      links: %{"GitHub" => @url}
    }
  end

  defp build_docs(_) do
    Mix.Task.run("compile")
    ex_doc = Path.join(Mix.Local.path_for(:escript), "ex_doc")

    unless File.exists?(ex_doc) do
      raise "cannot build docs because escript for ex_doc is not installed"
    end

    args = ["SRTM", @version, Mix.Project.compile_path()]
    opts = ~w[--main SRTM --source-ref v#{@version} --source-url #{@url}]
    System.cmd(ex_doc, args ++ opts)
    Mix.shell().info("Docs built successfully")
  end
end
