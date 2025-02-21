defmodule ExWebTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_web_tools,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:phoenix, "~> 1.7.19"},
      {:phoenix_live_view, "~> 1.0.4"}
    ]
  end
end
