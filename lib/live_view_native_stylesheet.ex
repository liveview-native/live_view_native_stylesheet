defmodule LiveViewNative.Stylesheet do
  defmacro __using__(format) do
    case LiveViewNative.Stylesheet.Rules.fetch_parser(format) do
      {:ok, parser} ->
        quote do
          import LiveViewNative.Stylesheet.Sheet, only: [sigil_SHEET: 2]
          import unquote(parser), only: [sigil_RULES: 2]
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
      {:error, message} -> raise message
    end
  end
end
