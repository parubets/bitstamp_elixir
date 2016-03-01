defmodule BitstampElixir.Mixfile do
  use Mix.Project

  def project do
    [app: :bitstamp_elixir,
     version: "0.0.3",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      applications: [:httpotion],
      mod: {BitstampElixir, []}
    ]
  end

  defp deps do
    [
      {:ibrowse, "~> 4.2"},
      {:httpotion, "~> 2.2.2"},
      {:poison, "~> 2.1"}
    ]
  end
end
