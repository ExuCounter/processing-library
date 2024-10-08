defmodule ProcessingLibrary.MixProject do
  use Mix.Project

  def project do
    [
      app: :processing_library,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ProcessingLibrary.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.

  defp deps do
    [
      {:redix, "~> 1.1"},
      {:jason, "~> 1.4"},
      {:uuid, "~> 1.1"}
    ]
  end
end
