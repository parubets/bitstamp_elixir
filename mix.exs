defmodule BitstampElixir.Mixfile do
  use Mix.Project

  def project do
    [app: :bitstamp_elixir,
     version: "0.2.0",
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps,
     elixirc_options: [debug_info: false]]
  end

  def application do
    [
      applications: [:httpoison],
      mod: {BitstampElixir, []}
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 0.9.2"},
      {:poison, "~> 3.0"}
    ]
  end
end
