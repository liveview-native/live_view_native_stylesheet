defmodule LiveViewNative.Stylesheet.MixProject do
  use Mix.Project

  @version "0.3.0-rc.2"
  @source_url "https://github.com/liveview-native/live_view_native_stylesheet"

  def project do
    [
      app: :live_view_native_stylesheet,
      version: @version,
      elixir: "~> 1.15",
      description: description(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:live_view_native, "~> 0.3.0-rc.2"},
      {:nimble_parsec, "~> 1.3"},
      {:floki, ">= 0.30.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp description, do: "Stylesheet primitives for LiveView Native clients"

  defp package do
    %{
      maintainers: ["Brian Cardarella", "Nduati Kuria"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Built by DockYard, Expert Elixir & Phoenix Consultants" => "https://dockyard.com/phoenix-consulting"
      }
    }
  end
end
