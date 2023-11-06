defmodule MockSheet do
  use LiveViewNative.Stylesheet, :mock

  ~SHEET"""
  "color-hex-" <> number do
    rule-31
    rule-22
  end

  # this is a comment that isn't included in the output

  "color-yellow" do
    rule-21
  end

  "rule containing end" do
    rule-end
  end

  "named-argument" do
    rule-ime
  end
  """

  def class("color-red", _target) do
    ~RULES"""
    rule-1
    rule-3
    rule-4
    """
  end

  def class("color-blue", target: :watch) do
    ~RULES"""
    rule-4
    rule-5
    """
  end

  def class("color-blue", _target) do
    ~RULES"""
    rule-2
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
    rule-22
    rule-23
    """
  end

  def class("custom-" <> number, _target) do
    {number, ""} = Integer.parse(number)

    ~RULES"""
    rule-22
    """
  end

  def class(unmatched, target: target) do
    {:unmatched, "Stylesheet warning: Could not match on class: #{inspect(unmatched)} for target: #{inspect(target)}"}
  end
end
