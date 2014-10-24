defmodule Zulex.Mixfile do
  use Mix.Project


  def project do
    [app: :zulex,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end


  def application do
    [applications: [:logger],
     mod: {ZulEx, []}]
  end


  defp deps do
    [
      {:exactor, "~> 1.0.0"},
      {:ibrowse,   github: "cmullaparthi/ibrowse",   tag: "v4.1.0"},
      {:httpotion, github: "kemonomachi/httpotion",  tag: "v0.2.4"},
      {:jsex,      github: "talentdeficit/jsex",     tag: "v2.0.0"}
    ]
  end
end
