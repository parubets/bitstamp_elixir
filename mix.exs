defmodule BitstampElixir.Mixfile do
  use Mix.Project

  def project do
    [app: :bitstamp_elixir,
     version: "0.0.6",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [
      applications: [:httpoison],
      mod: {BitstampElixir, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.8.2"},
      {:poison, "~> 2.1"}
    ]
  end
end
