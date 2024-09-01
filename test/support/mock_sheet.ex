defmodule MockSheet do
  use LiveViewNative.Stylesheet, :mock

  ~SHEET"""
  "color-number-" <> number do
    rule-1
    rule-2{number }
  end

  # this is a comment that isn't included in the output

  "color-yellow" do
    rule-yellow
  end

  "t-class-1" do
    t-rules-1
  end

  "c-class-1" do
    c-rules-1
  end

  "rule-containing-end" do
    rule-end
  end

  "nil" do
    {nil}
  end
  """

  def class("color-three") do
    ~RULES"""
    rule-1
    rule-3
    rule-4
    """
  end

  def class("color-blue") do
    ~RULES"""
    rule-2
    """
  end

  def class("custom-" <> numbers) do
    [number_1, number_2] = String.split(numbers, "-")

    ~RULES"""
    rule-{ number_1 }
    rule-{ number_2 }
    """
  end

  def class("raise-" <> numbers) do
    [number_1, number_2] = String.split(numbers, ":")

    ~RULES"""
    rule-{ number_1 }
    rule-{ number_2 }
    """
  end
end
