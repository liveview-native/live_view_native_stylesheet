defmodule MockRulesHelpers do
  # Implements a parse/1 function that can be used to parse helper functions
  use LiveViewNative.Stylesheet.RulesParser.Helpers, additional: ["to_abc"]

  def to_abc(expr) when is_binary(expr) do
    # ...
  end
end
