defmodule Mix.Tasks.Lvn.Stylesheet.Setup.Config do
  use Mix.Task

  alias Mix.LiveViewNative.Context

  import Mix.Tasks.Lvn.Setup.Config, only: [
    run_changesets: 2,
    config_path_for: 1
  ]

  import Mix.LiveViewNative.CodeGen.Patch, only: [
    patch_mime_types: 4,
    patch_live_reload_patterns: 4
  ]

  import Mix.LiveViewNative.Stylesheet.CodeGen.Patch, only: [
    patch_stylesheet_dev: 4,
    patch_stylesheet_config: 4
  ]

  @shortdoc "Configure LiveView Native Stylesheet within a project"

  @moduledoc """
  #{@shortdoc}

  This setup will configure your app and generate stylesheets for each available client

      $ mix lvn.stylesheet.setup.config

  """

  @impl true
  @doc false
  def run(args) do
    if Mix.Project.umbrella?() do
      Mix.raise(
        "mix lvn.stylesheet.setup must be invoked from within your *_web application root directory"
      )
    end

    context = Context.build(args, __MODULE__)

    run_changesets(context, &build_changesets/1)

    context
  end

  def build_changesets(context) do
    config_path = config_path_for("config.exs")
    dev_path = config_path_for("dev.exs")

    [
      {patch_stylesheet_config_data(context), &patch_stylesheet_config/4, config_path},
      {patch_mime_types_data(context), &patch_mime_types/4, config_path},
      {patch_live_reload_patterns_data(context), &patch_live_reload_patterns/4, dev_path},
      {nil, &patch_stylesheet_dev/4, dev_path}
    ]
  end

  defp patch_stylesheet_config_data(_context) do
    Mix.LiveViewNative.plugins()
    |> Enum.map(&(elem(&1, 1).format))
  end


  defp patch_mime_types_data(_context) do
    [:styles]
  end

  defp patch_live_reload_patterns_data(context) do
    web_path = Mix.Phoenix.web_path(context.context_app)

    [
      ~s'~r"priv/static/*.styles$"',
      ~s'~r"#{ web_path }/styles/.*ex$"'
    ]
  end

  @doc false
  def switches, do: [
    context_app: :string,
    web: :string,
    stylesheet: :boolean,
    live_form: :boolean
  ]

  @doc false
  def validate_args!([]), do: [nil]
  def validate_args!(_args) do
    Mix.raise("""
    mix lvn.gen does not take any arguments, only the following switches:

    --context-app
    --web
    --no-stylesheet
    --no-live-form
    """)
  end
end
