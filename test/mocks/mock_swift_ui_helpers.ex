defmodule MockSwiftUIHelpers do
  # Implements a parse/1 function that can be used to parse helper functions
  use LiveViewNative.Stylesheet.RulesParser.Helpers, additional: ["to_ime"]

  def to_ime(expr) when is_binary(expr) do
    # ...
  end
end
