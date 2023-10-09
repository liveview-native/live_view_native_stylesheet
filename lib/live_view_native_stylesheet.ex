defmodule LiveViewNative.Stylesheet do

  defmacro __using__(format) do
    compiler = LiveViewNative.Stylesheet.Compiler.fetch(format)

    quote do
      require unquote(compiler)
      import unquote(compiler), only: [sigil_SHEET: 2, sigil_RULES: 2]
      @sheet_format unquote(format)

      def compile(class_list, target: target) do
        Enum.reduce(class_list, %{}, fn(class_name, class_map) ->
          case class(class_name, target: target) do
            {:unmatched, msg} -> class_map
            rules -> Map.put(class_map, class_name, rules)
          end
        end)
      end
    end
  end

end
