defmodule LiveViewNative.Stylesheet do
  defmacro __using__(format) do
    stylesheet_module = __CALLER__.module

    case LiveViewNative.Stylesheet.RulesParser.fetch(format) do
      {:ok, parser} ->
        quote do
          # This nested `__using__` macro is required to allow LiveViews
          # and Live Components to inherit stylesheets via `use`
          defmacro __using__(opts \\ []) do
            inheriting_module = __CALLER__.module

            # Append this module to working list of inherited stylesheets
            quote bind_quoted: [opts: opts, inheriting_module: inheriting_module, stylesheet_module: unquote(stylesheet_module)] do
              @__stylesheet_modules__ Module.get_attribute(inheriting_module, :__stylesheet_modules__, []) ++ [stylesheet_module]
              defoverridable __stylesheet_modules__: 0
              def __stylesheet_modules__, do: @__stylesheet_modules__
            end
          end

          import LiveViewNative.Stylesheet.SheetParser, only: [sigil_SHEET: 2]
          import LiveViewNative.Stylesheet.RulesHelpers

          use unquote(parser)

          @sheet_format unquote(format)

          def compile_ast(class_or_list, target \\ [target: :all])
          def compile_ast(class_or_list, target: target) do
            class_or_list
            |> List.wrap()
            |> Enum.reduce(%{}, fn(class_name, class_map) ->
              case class(class_name, target: target) do
                {:unmatched, msg} -> class_map
                rules -> Map.put(class_map, class_name, List.wrap(rules))
              end
            end)
          end

          def compile_string(class_or_list, target \\ [target: :all]) do
            compile_ast(class_or_list, target) |> inspect(limit: :infinity, charlists: :as_list, printable_limit: :infinity)
          end

        end
      {:error, message} -> raise message
    end
  end
end
