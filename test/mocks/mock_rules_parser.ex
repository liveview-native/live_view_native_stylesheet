defmodule MockRulesParser do
  # @behaviour LiveViewNative.Stylesheet.parser
  use LiveViewNative.Stylesheet.Rules, :mock

  def parse(rules) do
    rules
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_rule(&1))
  end

  defp parse_rule("rule-31") do
    {:<>, [], ["rule-31-", {Elixir, [], {:number, [], Elixir}}]}
  end

  defp parse_rule("rule-21") do
    {:foobar, [], [1, 2, 3]}
  end

  defp parse_rule("rule-22") do
    {:foobar, [], [1, 2, {Elixir, [], {:number, [], Elixir}}]}
  end

  defp parse_rule("rule-" <> number) do
    number
    |> Integer.parse()
    |> elem(0)
  end

  defp parse_rule(rule), do: rule
end
