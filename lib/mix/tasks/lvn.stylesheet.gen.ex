defmodule Mix.Tasks.Lvn.Stylesheet.Gen do
  alias Mix.LiveViewNative.Context

  def run(args) do
    context = Context.build(args, __MODULE__)

    files = files_to_be_generated(context)

    Context.prompt_for_conflicts(files)

    copy_new_files(context, files)
  end

  def switches, do: [
    context_app: :string,
    web: :string
  ]

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
    schema_name = Phoenix.Naming.underscore(schema_module)

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
