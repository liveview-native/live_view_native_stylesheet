defmodule LiveViewNative.Stylesheet.SheetParser.HelperFunctions do
  @moduledoc false
  import NimbleParsec

  @helper_functions [
    "to_atom",
    "to_integer",
    "to_float",
    "to_boolean",
    "camelize",
    "snake_case"
  ]

  def helper_function do
    choice(Enum.map(@helper_functions, &string(&1)))
  end
end
