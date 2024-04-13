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
          {:my_custom_lib, "lib/**/*swiftui*"},
          {:other_lib, [
            "lib/**/*swiftui*",
            "priv/**/*swiftui*"
          ]}
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

  ## Importing other sheets

  Class names defined in another sheet can be importd into your sheet. The classes will
  be defined *below* your definitions which gives your classes priority. Search order for a matching
  class is in the order of the imports defined.

      defmodule MyAppWeb.Style.SwifUI do
        use LiveViewNative.Stylesheet, :swiftui

        @import LiveViewnative.SwiftUI.UtilityClasses
      end

  To prevent child sheets from producing their own stylesheet when compiled set `@export` to `true`

      defmodule MyStyleLib.SwiftUI do
        use LiveViewNative.Stylesheet, :swiftui
        @export true

        ~SHEET"""
          ...
        """
      end
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
      Module.register_attribute(__MODULE__, :import, accumulate: true)

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
    end
  end

  def unmatched_handler(unmatched, %{imports: imports}) do
    result = {:unmatched, "Stylesheet warning: Could not match on class: #{inspect(unmatched)}"}

    Enum.reduce_while(imports, result, fn(sheet, result) ->
      sheet.class(unmatched)
      |> case do
        {:unmatched, _msg} -> {:cont, result}
        result -> {:halt, result}
      end
    end)
  end

  @doc false
  defmacro __before_compile__(env) do
    format = Module.get_attribute(env.module, :format)
    export? = Module.get_attribute(env.module, :export, false)
    imports = Module.get_attribute(env.module, :import, [])

    if export? do
      native_opts = %{
        imports: imports,
        export?: export?
      }

      quote do
        def __native_opts__ do
          unquote(Macro.escape(native_opts))
        end

        def class(unmatched) do
          LiveViewNative.Stylesheet.unmatched_handler(unmatched, __native_opts__())
        end
      end
    else
      output = Application.get_env(:live_view_native_stylesheet, :output)

      paths =
        env.file
        |> Path.relative_to_cwd()
        |> LiveViewNative.Stylesheet.Extractor.paths(format)

      filename =
        Path.basename(env.file)
        |> String.split(".ex")
        |> Enum.at(0)
        |> Kernel.<>(".styles")

      file_hash = :erlang.md5(paths)

      content =
        Application.get_env(:live_view_native_stylesheet, :content, [])
        |> Keyword.get(format, [])

      native_opts = %{
        imports: imports,
        export?: export?,
        paths: paths,
        filename: filename,
        format: format,
        config: %{
          content: content,
          output: output
        }
      }

      quote do
        @stylesheet_paths unquote(paths)
        @stylesheet_paths_hash unquote(file_hash)

        for path <- unquote(paths) do
          @external_resource path
        end

        def __native_opts__ do
          unquote(Macro.escape(native_opts))
        end

        def class(unmatched) do
          LiveViewNative.Stylesheet.unmatched_handler(unmatched, __native_opts__())
        end

        def __mix_recompile__? do
          native_opts = __native_opts__()

          output_file_exists? =
            native_opts
            |> get_in([:config, :output])
            |> Path.join(native_opts[:filename])
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
  end

  @doc false
  def __after_verify__(module) do
    native_opts = module.__native_opts__()

    unless Map.get(native_opts, :export?, false) do
      compiled_sheet =
        native_opts
        |> LiveViewNative.Stylesheet.Extractor.run()
        |> module.compile_string()

      file_path =
        native_opts
        |> get_in([:config, :output])
        |> Path.join(native_opts[:filename])

      file_path
      |> Path.dirname()
      |> File.mkdir_p!()

      File.write(file_path, compiled_sheet)
    end
  end
end
