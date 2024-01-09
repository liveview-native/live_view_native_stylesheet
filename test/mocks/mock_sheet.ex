defmodule MockSheet do
  use LiveViewNative.Stylesheet, :mock
  require LiveViewNative.Stylesheet.RulesParser

  ~SHEET"""
  # this is a comment that isn't included in the output
  "color-yellow" do
    rule-foobar
  end

  "rule-containing-end" do
    rule-end
  end

  "named-argument" do
    rule-ime
  end
  """

  def class("color-red", _target) do
    ~RULES"""
    color-red-1
    color-red-2
    color-red-3
    """
  end

  def class("color-blue", target: :watch) do
    ~RULES"""
    color-sky-1
    color-sky-2
    """
  end

  def class("color-blue", _target) do
    ~RULES"""
    color-blue-3
    """
  end

  def class("single", _target) do
    {:single, [], [1]}
  end

  def class("custom-multi-" <> numbers, _target) do
    [number, number2] = String.split(numbers, "-")
    {number, ""} = Integer.parse(number)
    {number2, ""} = Integer.parse(number2)

    ~RULES"""
    rule-foobar-<%= number %>
    rule-bazqux-<%= number2 %>
    """
  end

  def class("custom-interpolate-" <> str, _target) do
    [ime_str, _] = String.split(str,"-")

    ~RULES"""
    rule-<%= ime_str %>
    """
  end

  def class("custom-" <> number, _target) do
    {number, ""} = Integer.parse(number)

    ~RULES"""
    rule-number-<%= number %>
    """
  end

  def class(unmatched, target: target) do
    {:unmatched, "Stylesheet warning: Could not match on class: #{inspect(unmatched)} for target: #{inspect(target)}"}
  end
end
