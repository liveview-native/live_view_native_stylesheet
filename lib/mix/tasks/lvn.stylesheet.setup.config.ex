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
    build_file_map: 1,
    write_files: 1
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

    args
    |> Context.build(__MODULE__)
    |> run_config()
  end

  @doc false
  def run_config(context) do
    source_files = build_file_map(%{
      config: "config/config.exs",
      dev: "config/dev.exs"
    })

    config({context, source_files})
    |> write_files()

    context
  end

  @doc false
  def run_generators(context) do

    Mix.Task.run("lvn.stylesheet.gen", [])

    context
  end

  @doc false
  def config({context, source_files}) do
    {context, source_files}
    |> patch_config()
    |> patch_dev()
  end

  @doc false
  def patch_config({context, %{config: {source, path}} = source_files}) do
    {_context, source} =
      {context, source}
      |> patch_stylesheet_config()

    {context, %{source_files | config: {source, path}}}
  end

  @doc false
  def patch_stylesheet_config({context, source}) do
    formats =
      Mix.LiveViewNative.plugins()
      |> Enum.map(&(elem(&1, 1).format))
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

    source = CodeGen.patch(source, change, merge: &merge_stylesheet_config/2, inject: {:before, matcher}, fail_msg: fail_msg)

    {context, source}
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

  @doc false
  def patch_dev({context, %{dev: {source, path}} = source_files}) do

    {_context, source} =
      {context, source}
      |> patch_live_reload_patterns()
      |> patch_stylesheet_dev()

    {context, %{source_files | dev: {source, path}}}
  end

  @doc false
  def patch_live_reload_patterns({context, source}) do
    web_path = Mix.Phoenix.web_path(context.context_app)

    change = """
    [
      ~r"priv/static/*.styles$",
      ~r"<%= web_path %>/styles/*.ex$"
    ]
    """
    |> compile_string()

    fail_msg = """
    failed to merge the following live_reload pattern into config/dev.exs

    #{change}

    you can do this manually or inspect config/dev.exs for errors and try again
    """

    source = CodeGen.patch(source, change, merge: &merge_live_reload_patterns/2, fail_msg: fail_msg)

    {context, source}
  end

  defp merge_live_reload_patterns(source, change) do
    quoted_change_list = Sourceror.parse_string!(change)

    source
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Zipper.find(&match?({{:__block__, _, [:live_reload]}, {:__block__, _, [[{{:__block__, _, [:patterns]}, _patterns} | _]]}}, &1))
    |> case do
      nil -> :error
      %{node: {{:__block__, _, [:live_reload]}, {:__block__, _, [[{{:__block__, _, [:patterns]}, quoted_source_list} | _]]}}} ->
        range = Sourceror.get_range(quoted_source_list)
        {:__block__, _, [quoted_source_members]} = quoted_source_list
        {:__block__, _, [quoted_change_members]} = quoted_change_list

        source_list = Enum.map(quoted_source_members, &Sourceror.to_string/1)
        change_list = Enum.map(quoted_change_members, &Sourceror.to_string/1)

        patterns = Enum.uniq(source_list ++ change_list)

        change = """
          [<%= for pattern <- patterns do %>
            <%= pattern %><%= unless last?(patterns, pattern) do %>,<% end %><% end %>
          ]
          """
          |> compile_string()
          |> String.trim()

        [build_patch(range, change)]
    end
  end

  def patch_stylesheet_dev({context, source}) do
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

    source = CodeGen.patch(source, change, merge: &merge_stylesheet_dev/2, inject: :eof, fail_msg: fail_msg)

    {context, source}
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
