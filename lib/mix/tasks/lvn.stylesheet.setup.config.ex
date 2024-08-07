defmodule Mix.Tasks.Lvn.Stylesheet.Setup.Config do
  use Mix.Task

  alias Mix.LiveViewNative.{CodeGen, Context}
  alias Sourceror.Zipper

  import Mix.LiveViewNative.Context, only: [
    compile_string: 1,
    last?: 2
  ]

  import Mix.LiveViewNative.CodeGen, only: [
    build_patch: 2
  ]

  import Mix.Tasks.Lvn.Setup.Config, only: [
    run_changesets: 2,
    patch_mime_types: 4,
    patch_live_reload_patterns: 4
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

  defp build_changesets(context) do
    [
      {patch_stylesheet_config_data(context), &patch_stylesheet_config/4, "config/config.exs"},
      {patch_mime_types_data(context), &patch_mime_types/4, "config/config.exs"},
      {patch_live_reload_patterns_data(context), &patch_live_reload_patterns/4, "config/dev.exs"},
      {nil, &patch_stylesheet_dev/4, "config/dev.exs"}
    ]
  end

  defp patch_stylesheet_config_data(_context) do
    Mix.LiveViewNative.plugins()
    |> Enum.map(&(elem(&1, 1).format))
  end

  @doc false
  def patch_stylesheet_config(_context, formats, source, path) do
    formats =
      formats
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    change = """
    config :live_view_native_stylesheet,
      content: [<%= for format <- formats do %>
        <%= format %>: [
          "lib/**/<%= format %>/*",
          "lib/**/*<%= format %>*"
        ]<%= unless last?(formats, format) do %>,<% end %><% end %>
      ],
      output: "priv/static/assets"

    """
    |> compile_string()

    matcher = &(match?({:import_config, _, _}, &1))

    fail_msg = """
    failed to merge or inject the following in code into config/config.exs

    #{change}

    you can do this manually or inspect config/config.exs for errors and try again
    """

    CodeGen.patch(source, change, merge: &merge_stylesheet_config/2, inject: {:before, matcher}, fail_msg: fail_msg, path: path)
  end

  defp merge_stylesheet_config(source, change) do
    quoted_change = Sourceror.parse_string!(change)

    source
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Zipper.find(&match?({:config, _, [{:__block__, _, [:live_view_native_stylesheet]} | _]}, &1))
    |> case do
      nil -> :error
      found ->
        Zipper.find(found, &match?({{:__block__, _, [:content]}, _}, &1))
        |> case do
          nil -> :error
          %{node: {{:__block__, _, [:content]}, quoted_source_block}} ->
            {:config, _, [_, [{_, quoted_change_block} | _]]} = quoted_change
            range = Sourceror.get_range(quoted_source_block)
            source_list = Code.eval_quoted(quoted_source_block) |> elem(0)
            change_list = Code.eval_quoted(quoted_change_block) |> elem(0)

            formats =
              (source_list ++ change_list)
              |> Enum.uniq_by(fn({format, _}) -> format end)
              |> Enum.sort_by(fn({format, _}) -> format end)

            change = """
              [<%= for {format, patterns}  <- formats do %>
                <%= format %>: [<%= for pattern <- patterns do %>
                  <%= inspect pattern %><%= unless last?(patterns, pattern) do %>,<% end %><% end %>
                ]<%= unless last?(formats, {format, patterns}) do %>,<% end %><% end %>
              ]
              """
              |> compile_string()
              |> String.trim()

            [build_patch(range, change)]
        end
    end
  end

  defp patch_mime_types_data(_context) do
    [:styles]
  end

  defp patch_live_reload_patterns_data(context) do
    web_path = Mix.Phoenix.web_path(context.context_app)

    [
      ~s'~r"priv/static/*.styles$"',
      ~s'~r"#{ web_path }/styles/*.ex$"'
    ]
  end

  def patch_stylesheet_dev(_context, _data, source, path) do
    change = """

    config :live_view_native_stylesheet,
      annotations: true,
      pretty: true
    """
    |> compile_string()

    fail_msg = """
    failed to merge or inject the following in code into config/dev.exs

    #{change}

    you can do this manually or inspect config/config.exs for errors and try again
    """

    CodeGen.patch(source, change, merge: &merge_stylesheet_dev/2, inject: :eof, fail_msg: fail_msg, path: path)
  end

  defp merge_stylesheet_dev(source, _change) do
    source
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Zipper.find(&match?({:config, _, [{:__block__, _, [:live_view_native_stylesheet]}, options]} when is_list(options), &1))
    |> case do
      nil -> :error
      _found ->
        []
    end
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
