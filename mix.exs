defmodule Beabadoobee.MixProject do
  use Mix.Project

  def project do
    [
      app: :beabadoobee,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Beabadoobee.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, github: "Leastrio/nostrum"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:jason, ">= 1.0.0"},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:veritaserum, "~> 0.2.2"}
    ]
  end
end
