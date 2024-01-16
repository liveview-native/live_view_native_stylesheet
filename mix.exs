defmodule LiveViewNative.Stylesheet.MixProject do
  use Mix.Project

  @version "0.2.0"
  @scm_url "https://github.com/liveview-native/live_view_native_stylesheet"

  def project do
    [
      app: :live_view_native_stylesheet,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      docs: docs(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Brian Cardarella", "Nduati Kuria"],
      licenses: ["MIT"],
      links: %{"GitHub" => @scm_url},
      files:
        ~w(lib CHANGELOG.md LICENSE.md mix.exs README.md .formatter.exs)
    ]
  end

  defp description, do: "Stylesheet primitives for LiveView Native clients"

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md"]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:live_view_native, path: "../live_view_native"},
      {:live_view_native, github: "liveview-native/live_view_native"},
      {:nimble_parsec, "~> 1.3"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
