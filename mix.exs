defmodule Marvin.MixProject do
  use Mix.Project

  def project do
    [
      app: :marvin,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      xref: [
        exclude: [
          {IEx, :started?, 0}
        ]
      ],
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Marvin, []},
      extra_applications: [:logger, :eex],
      env: [
        logger: true
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:telemetry, "~> 1.2"},
      {:ex_gram, "~> 0.34.0"},
      {:tesla, "~> 1.2"},
      {:hackney, "~> 1.12"},
      {:jason, "~> 1.4"},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:telemetry_poller, "~> 1.0", only: [:docs, :test]},
      {:telemetry_metrics, "~> 0.6", only: [:docs, :test]}
    ]
  end
end
