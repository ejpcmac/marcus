defmodule Marcus.MixProject do
  use Mix.Project

  @version "0.1.1-dev"
  @repo_url "https://github.com/ejpcmac/marcus"

  def project do
    [
      app: :marcus,
      version: @version,
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Tools
      dialyzer: dialyzer(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: cli_env(),

      # Docs
      docs: [
        main: "Marcus",
        source_url: @repo_url,
        source_ref: "v#{@version}"
      ],

      # Package
      package: package(),
      description: "A library for writing interactive CLIs."
    ]
  end

  defp deps do
    [
      # Development and test dependencies
      {:credo, "~> 0.10.0", only: :dev, runtime: false},
      {:dialyxir, ">= 0.0.0", only: :dev, runtime: false},
      {:excoveralls, ">= 0.0.0", only: :test, runtime: false},
      {:mix_test_watch, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_unit_notifier, ">= 0.0.0", only: :test, runtime: false},
      {:stream_data, "~> 0.4.0", only: :test},

      # Project dependencies

      # Documentation dependencies
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  # Dialyzer configuration
  defp dialyzer do
    [
      plt_add_deps: :transitive,
      flags: [
        :unmatched_returns,
        :error_handling,
        :race_conditions
      ],
      ignore_warnings: ".dialyzer_ignore"
    ]
  end

  defp cli_env do
    [
      # Always run coveralls mix tasks in `:test` env.
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.html": :test
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @repo_url}
    ]
  end
end
