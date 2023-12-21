defmodule MockRulesParser do
  use LiveViewNative.Stylesheet.RulesParser, :mock

  defmacro __using__(_) do
    quote do
      import MockRulesParser, only: [sigil_RULES: 2]
    end
  end

  def parse(rules, opts) do
    rules
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_rule(&1, opts))
  end

  defp parse_rule("color-" <> color_and_number, _opts) do
    [color, number] = String.split(color_and_number, "-")
    {color, number}
  end

  defp parse_rule("rule-foobar", _opts) do
    {:foobar, [], [1, 2, 3]}
  end

  defp parse_rule("rule-foobar-annotated", opts) do
    {:foobar,
     [
       file: Keyword.get(opts, :file),
       line: Keyword.get(opts, :line),
       module: Keyword.get(opts, :module)
     ], [1, 2, 3]}
  end

  defp parse_rule("rule-foobar-" <> number, _opts) do
    number = String.to_integer(number)
    {:foobar, [], [1, 2, number]}
  end

  defp parse_rule("rule-bazqux-" <> number, _opts) do
    number = String.to_integer(number)
    {:bazqux, [], [3, 4, number]}
  end

  defp parse_rule("rule-ime", _opts) do
    {:color, [], [color: [{:., [], [nil, :red]}]]}
  end

  defp parse_rule("rule-end", _) do
    {:foobar, [], [1, 2]}
  end

  defp parse_rule("rule-number-" <> number, _) do
    number
    |> Integer.parse()
    |> elem(0)
  end

  defp parse_rule(rule, _), do: rule
end
