defmodule Mix.Tasks.Lvn.Stylesheet.Gen do
  use Mix.Task

  alias Mix.LiveViewNative.Context
  import Mix.LiveViewNative.Context, only: [
    compile_string: 1,
    last?: 2
  ]

  @shortdoc "Generates a new format specific stylesheet"

  @moduledoc """
  #{@shortdoc}

      $ mix lvn.stylesheet gen.live swiftui App

  ## Options

  * `--no-copy` - don't copy the styelsheet module into your application
  * `--no-info` - don't print configuration info
  """

  @impl true
  @doc false
  def run(args) do
    {opts, _parsed, _invalid} = OptionParser.parse(args, switches: switches())

    if Keyword.get(opts, :copy, true) do
      context = Context.build(args, __MODULE__)
      files = files_to_be_generated(context)

      Context.prompt_for_conflicts(files)

      copy_new_files(context, files)
    end

    if Keyword.get(opts, :info, true) do
      print_shell_instructions(opts)
    end
  end

  defp print_shell_instructions(opts) do
    print_config()
    print_dev(opts)
  end

  defp print_config() do
    plugins =
      LiveViewNative.plugins()
      |> Map.values()

    plugins? = length(plugins) > 0

    """
    \e[93;1m# config/config.exs\e[0m

    # \e[91;1mLVN - Required\e[0m
    # You must configure LiveView Native Stylesheets
    # on which file path patterns class names should be extracted from
    \e[32;1mconfig :live_view_native_stylesheet,
      content: [<%= if plugins? do %><%= for plugin <- plugins do %>
        <%= plugin.format %>: [
          "lib/**/*<%= plugin.format %>*"
        ]<%= unless last?(plugins, plugin) do %>,<% end %><% end %><% else %>
        # swiftui: ["lib/**/*swiftui*"]<% end %>
      ],
      output: "priv/static/assets"\e[0m

    # \e[36mLVN - Optional\e[0m
    # If you want to inspect LVN stylesheets from your browser add the `style` type
    config :mime, :types, %{
      \e[32;1m"text/styles" => ["styles"]\e[0m
    }
    """
    |> compile_string()
    |> Mix.shell().info()
  end

  defp print_dev(opts) do
    context_app = opts[:context_app] || Mix.Phoenix.context_app()
    base_module = Module.concat([Mix.Phoenix.context_base(context_app)])
    web_module = Mix.Phoenix.web_module(base_module)

    context = %{
      context_app: context_app,
      web_module: web_module
    }

    stylesheet? =
      Mix.Project.deps_apps()
      |> Enum.member?(:live_view_native_stylesheet)

    if stylesheet? do
      """
      \e[93;1m# config/dev.exs\e[0m

      # \e[36mLVN - Optional\e[0m
      # Allows LVN stylesheets to be subject to LiveReload changes
      config :<% context.context_app %>, <%= inspect context.web_module %>.Endpoint,
        live_reload: [
          patterns: [
            ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
            ~r"priv/gettext/.*(po)$",
            ~r"lib/anotherone_web/(controllers|live|components\e[32;1m|styles\e[0m)/.*(ex|heex)$"
          ]
        ]

      # \e[36mLVN - Optional\e[0m
      # Adds dev mode stylesheet annotations for client IDEs and expands stylsheets visually
      \e[32;1mconfig :live_view_native_stylesheet,
        annotations: true,
        pretty: true\e[0m
      """
      |> compile_string()
      |> Mix.shell().info()
    end

    context
  end

  @doc false
  def switches, do: [
    context_app: :string,
    web: :string,
    info: :boolean,
    copy: :boolean
  ]

  @doc false
  def validate_args!([]) do
    formats =
      LiveViewNative.available_formats()
      |> Enum.map(&("* #{&1}"))
      |> Enum.join("\n")

    Mix.raise("""
    You must pass a valid format and schema. Available formats:
    #{formats}
    """)
  end

  def validate_args!([format, schema | []] = args) do
    cond do
      not Context.valid_format?(format) ->
        formats =
          LiveViewNative.available_formats()
          |> Enum.map(&("* #{&1}"))
          |> Enum.join("\n")

        Mix.raise("""
        #{format} is an unregistered format.
        Available formats:
        #{formats}

        Please see the documentation for how to register new LiveView Native plugins
        """)

      not Mix.Phoenix.Schema.valid?(schema) ->
        Mix.raise("Expected the schema, #{inspect(schema)}, to be a valid module name")
      true ->
        args
    end
  end

  def validate_args!(args) do
    Mix.raise("format and schema are required arguments. You passed #{Enum.join(args, ", ")}")
  end

  defp files_to_be_generated(%Context{format: format, schema_module: schema_module, context_app: context_app}) do
    web_prefix = Mix.Phoenix.web_path(context_app)
    schema_name = Macro.underscore(schema_module)

    styles_path = Path.join(web_prefix, "styles")

    [{:eex, "sheet.ex", Path.join(styles_path, "#{schema_name}.#{format}.ex")},]
  end

  defp copy_new_files(%Context{} = context, files) do
    binding = [
      context: context,
      assigns: %{}
    ]

    apps = Context.apps(context.format, :live_view_native_stylesheet)

    Mix.Phoenix.copy_from(apps, "priv/templates/lvn.gen.stylesheet", binding, files)

    context
  end
end
