defmodule LiveViewNative.Stylesheet do
  defmacro __using__(format) do
    case LiveViewNative.Stylesheet.RulesParser.fetch(format) do
      {:ok, parser} ->
        quote do
          import LiveViewNative.Stylesheet.SheetParser, only: [sigil_SHEET: 2]
          import LiveViewNative.Stylesheet.RulesHelpers

          use unquote(parser)

          @sheet_format unquote(format)

          def compile(class_or_list, target \\ [target: :all])
          def compile(class_list, target: target) do
            class_list
            |> List.wrap()
            |> Enum.reduce(%{}, fn(class_name, class_map) ->
              case class(class_name, target: target) do
                {:unmatched, msg} -> class_map
                rules -> Map.put(class_map, class_name, List.wrap(rules))
              end
            end)
          end
        end
      {:error, message} -> raise message
    end
  end
end
