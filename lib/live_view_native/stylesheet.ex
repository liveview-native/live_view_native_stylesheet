defmodule LiveViewNative.Stylesheet do
  @moduledoc ~S'''
  Add LiveView Native Stylesheet to your app

  Stylesheets are format-specific. The rules for parsing style rules
  are defined in each client library. This library provides support for
  defining and compiling stylesheets.

  ## Configuration

  You must configure your application to know which files to parse class names from.
  LiveView Native Stylesheets borrows the same class name extracting logic as Tailwind:

  [Tailwind - Dynamic class names](https://tailwindcss.com/docs/content-configuration#dynamic-class-names)

      config :live_view_native,
        content: [
          swiftui: [
            "lib/**/*swiftui*"
          ],
          jetpack: [
            "lib/**/*jetpack*"
          ]
        ],
        output: "priv/static/assets/"

  Because class names may be shared betweeen different formats you should try to ensure
  that the `content` pattern for that format is as targetd as possible.

  You can also search dependencies by adding a tuple `{opt_app_name, pattern}` to the list
  for a format:

      content: [
        swifti: [
          "lib/**/*swiftui*",
          {:my_custom_lib, "lib/**/*swiftui*"}
        ]
      ],
      output: "priv/static/assets/"

  ## Optional configuration

  By default LiveView Native Stylesheet will emit the most concise format possible.
  In `dev` mode you may want to expand the formatting and include annotations:

      config :live_view_native_stylesheet,
        annotations: true,
        pretty: true

  With annotations tured on the native clients will have more information on how to report
  erors and warnings in its logger.
  '''

  @doc ~S'''
  Using in a module allows for stylesheet compilation

      defmodule MyAppWeb.Style.SwiftUI do
        use LiveViewNative.Stylesheet, :swiftui

        ~SHEET"""
          "padding:" <> padding do
            padding({padding})
          end
        """
      end

  The following functions are injected into the module:

    * `compile_ast/1` - takes a list of class names, produces AST as an Elixir map
    * `compile_string/1` - takes a list of class names, produces a string of the AST.
    Formatting rules are applied from the `live_view_native_stylesheet` application config.
  '''
  defmacro __using__(format) do
    %{module: module} = __CALLER__

    Module.put_attribute(module, :native_opts, %{
      format: format,
    })

    quote do
      import LiveViewNative.Stylesheet.SheetParser, only: [sigil_SHEET: 2]
      import LiveViewNative.Stylesheet.RulesParser, only: [sigil_RULES: 2]

      @format unquote(format)
      @before_compile LiveViewNative.Stylesheet
      @after_verify LiveViewNative.Stylesheet

      def compile_ast(class_or_list) do
        class_or_list
        |> List.wrap()
        |> Enum.reduce(%{}, fn(class_name, class_map) ->
          try do
            class(class_name)
          rescue
            e ->
              require Logger
              Logger.error(Exception.format(:error, e, __STACKTRACE__))
              {:error, nil}
          end
          |> case do
            {:error, _msg} -> class_map
            {:unmatched, _msg} -> class_map
            rules ->
              Map.put(class_map, class_name, List.wrap(rules))
          end
        end)
      end

      def compile_string(class_or_list) do
        pretty = Application.get_env(:live_view_native_stylesheet, :pretty, false)

        class_or_list
        |> compile_ast()
        |> inspect(limit: :infinity, charlists: :as_list, printable_limit: :infinity, pretty: pretty)
      end


      def __native_opts__ do
        %{format: unquote(format)}
      end
    end
  end

  def filename(module) do
    format = module.__native_opts__()[:format]

    module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> Kernel.<>(".#{format}.styles")
  end

  def file_path(module) do
    Application.get_env(:live_view_native_stylesheet, :output)
    |> Path.join(filename(module))
  end

  @doc false
  defmacro __before_compile__(env) do
    format = Module.get_attribute(env.module, :format)

    paths =
      env.file
      |> Path.relative_to_cwd()
      |> LiveViewNative.Stylesheet.Extractor.paths(format)

    file_hash = :erlang.md5(paths)

    quote do
      @stylesheet_paths unquote(paths)
      @stylesheet_paths_hash unquote(file_hash)

      for path <- unquote(paths) do
        @external_resource path
      end

      def class(unmatched) do
        {:unmatched, "Stylesheet warning: Could not match on class: #{inspect(unmatched)}"}
      end

      def __stylesheet__ do
        content =
          Application.get_env(:live_view_native_stylesheet, :content, [])
          |> Keyword.get(@format, [])

        %{
          paths: @stylesheet_paths,
          format: @format,
          config: %{
            content: content,
            output: LiveViewNative.Stylesheet.file_path(__MODULE__)
          }
        }
      end

      def __mix_recompile__? do
        output_file_exists? =
          __stylesheet__()
          |> get_in([:config, :output])
          |> File.exists?()

        file_hash =
          unquote(env.file)
          |> Path.relative_to_cwd()
          |> LiveViewNative.Stylesheet.Extractor.paths(@format)
          |> :erlang.md5()

        !(output_file_exists? && @stylesheet_paths_hash == file_hash)
      end
    end
  end

  @doc false
  def __after_verify__(module) do
    compiled_sheet =
      module.__stylesheet__()
      |> LiveViewNative.Stylesheet.Extractor.run()
      |> module.compile_string()

    output_path = file_path(module)

    output_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write(output_path, compiled_sheet)
  end
end
