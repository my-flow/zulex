defmodule Zulex.Mixfile do
  use Mix.Project


  def project do
    [
      app: :zulex,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      package: package,
      dialyzer: [
        plt_add_apps: [:ibrowse, :httpotion, :jsex, :jsx]
      ]
    ]
  end


  def application do
    [
      applications: [:logger],
      mod: {ZulEx, []}
    ]
  end


  defp deps do
    [
      {:exactor, "~> 1.0.0"},
      {:ibrowse,   github: "cmullaparthi/ibrowse",   tag: "v4.1.1"},
      {:httpotion, github: "my-flow/httpotion",      branch: "master"},
      {:jsex,      github: "talentdeficit/jsex",     tag: "v2.0.0"},
      {:timex, "~> 0.13.0"}
    ]
  end


  defp package do
    [
      contributors: ["Florian J. Breunig"],
      links: %{ "GitHub" => "https://github.com/my-flow/zulex" }
    ]
  end
end
