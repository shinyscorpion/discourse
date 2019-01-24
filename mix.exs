defmodule Discourse.MixProject do
  use Mix.Project

  @version "0.0.1"

  def project do
    [
      app: :discourse,
      version: @version,
      description: "Simple Discourse library including SSO support.",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [ignore_warnings: ".dialyzer", plt_add_deps: true],

      # Docs
      name: "Discourse",
      source_ref: "v#{@version}",
      source_url: "https://github.com/shinyscorpion/discourse",
      homepage_url: "https://github.com/shinyscorpion/discourse",
      docs: [
        name: "Discourse",
        main: "readme",
        extras: ["README.md"],
        source_ref: "v#{@version}",
        source_url: "https://github.com/shinyscorpion/discourse"
      ]
    ]
  end

  defp package do
    [
      name: :discourse,
      files: [
        # Project files
        "mix.exs",
        "README*",
        "LICENSE*",
        # Discourse
        "lib/discourse.ex",
        "lib/discourse"
      ],
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/shinyscorpion/discourse"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Dev Only
      {:analyze, "~> 0.1.3", optional: true, runtime: false, only: [:dev, :test]},
      {:dialyxir, "~> 1.0.0-rc.4", optional: true, runtime: false, only: [:dev, :test]}
    ]
  end
end
