defmodule LiveViewNative.Stylesheet.SheetParser.HelperFunctions do
  @moduledoc false
  import NimbleParsec
  import LiveViewNative.Stylesheet.SheetParser.Tokens, only: [variable: 0, enclosed: 4]

  @helper_functions [
    "to_atom",
    "to_integer",
    "to_float",
    "to_boolean",
    "camelize",
    "underscore"
  ]

  def helper_function do
    choice(Enum.map(@helper_functions, &string(&1)))
    |> enclosed("(", variable(), ")")
    |> post_traverse({:to_function_call_ast, []})
    |> post_traverse({:tag_as_elixir_code, []})
  end
end
