defmodule ExWebTools.MixProject do
  use Mix.Project

  @version "0.0.1"
  @description "SEO optimization tools for Phoenix and Phoenix LiveView applications"
  @source_url "https://github.com/startkoden/ex_web_tools"

  def project do
    [
      app: :ex_web_tools,
      version: @version,
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      package: package(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.7.20"},
      {:phoenix_live_view, "~> 1.0.5"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:jason, "~> 1.0"}
    ]
  end

  defp package do
    [
      maintainers: ["Startkoden"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_url: @source_url
    ]
  end
end
