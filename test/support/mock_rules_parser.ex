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

  defp parse_rule("rule-31", opts) do
    {:<>, [], ["rule-31-", {Elixir, [], {:number, [], Keyword.get(opts, :variable_context)}}]}
  end

  defp parse_rule("rule-21", _opts) do
    {:foobar, [], [1, 2, 3]}
  end

  defp parse_rule("rule-21-annotated", opts) do
    {:foobar,
     [
       file: Keyword.get(opts, :file),
       line: Keyword.get(opts, :line),
       module: Keyword.get(opts, :module)
     ], [1, 2, 3]}
  end

  defp parse_rule("rule-22", opts) do
    {:foobar, [], [1, 2, {Elixir, [], {:number, [], Keyword.get(opts, :variable_context)}}]}
  end

  defp parse_rule("rule-23", opts) do
    {:bazqux, [], [3, 4, {Elixir, [], {:number2, [], Keyword.get(opts, :variable_context)}}]}
  end

  defp parse_rule("rule-ime", _opts) do
    {:color, [], [color: [{:., [], [nil, :red]}]]}
  end

  defp parse_rule("rule-end", _) do
    {:foobar, [], [1, 2]}
  end

  defp parse_rule("rule-" <> number, _) do
    number
    |> Integer.parse()
    |> elem(0)
  end

  defp parse_rule(rule, _), do: rule
end
