defmodule LiveViewNative.Stylesheet do
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

      def compile_ast(class_or_list, target \\ [target: :all])
      def compile_ast(class_or_list, target: target) do
        class_or_list
        |> List.wrap()
        |> Enum.reduce(%{}, fn(class_name, class_map) ->
          case class(class_name, target: target) do
            {:unmatched, msg} -> class_map
            rules ->
              Map.put(class_map, class_name, List.wrap(rules))
          end
        end)
      end

      def compile_string(class_or_list, target \\ [target: :all]) do
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

  defmacro __before_compile__(env) do
    sheet_path = Path.relative_to_cwd(env.file)

    quote do
      def __sheet_path__, do: unquote(sheet_path)

      def class(unmatched, target: target) do
        {:unmatched, "Stylesheet warning: Could not match on class: #{inspect(unmatched)} for target: #{inspect(target)}"}
      end
    end
  end
end
