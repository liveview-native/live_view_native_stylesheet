defmodule LiveViewNative.Stylesheet.RulesParser.Helpers do
  @moduledoc false
  import NimbleParsec
  import LiveViewNative.Stylesheet.SheetParser.Tokens, only: [variable: 0]
  import LiveViewNative.Stylesheet.SheetParser.Expressions, only: [enclosed: 5]
  alias LiveViewNative.Stylesheet.SheetParser.PostProcessors
  alias LiveViewNative.Stylesheet.SheetParser.Parser

  defp create_combinator(function_names) do
    Parser.start()
    |> pre_traverse({PostProcessors, :mark_line, [:open_function_line]})
    |> pre_traverse({PostProcessors, :mark_line, [:open_elixir_code]})
    |> choice(Enum.map(function_names, &string(&1)))
    |> enclosed("(", variable(), ")", [])
    |> post_traverse({PostProcessors, :to_function_call_ast, []})
    |> post_traverse({PostProcessors, :tag_as_elixir_code, []})
    |> post_traverse({PostProcessors, :unmark_line, [:open_function_line]})
    |> post_traverse({PostProcessors, :unmark_line, [:open_elixir_code]})
    |> label("a 1-arity helper function (#{Enum.join(function_names, ", ")})")
  end

  defmacro __using__(opts \\ []) do
    quote do
      import NimbleParsec

      import LiveViewNative.Stylesheet.SheetParser.PostProcessors,
        only: [to_function_call_ast: 5, to_elixir_variable_ast: 5, tag_as_elixir_code: 5]
    end
  end
end
