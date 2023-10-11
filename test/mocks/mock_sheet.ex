defmodule MockSheet do
  use LiveViewNative.Stylesheet, :mock

  ~SHEET"""
  "color-hex-" <> number do
    rule-31
    rule-22
  end

  "color-yellow" do
    rule-21
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

  def class(unmatched, target: target) do
    {:unmatched, "Stylesheet warning: Could not match on class: #{inspect(unmatched)} for target: #{inspect(target)}"}
  end
end
