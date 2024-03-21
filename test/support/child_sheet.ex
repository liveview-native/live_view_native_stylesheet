defmodule ChildSheet do
  use LiveViewNative.Stylesheet, :mock
  @output false

  ~SHEET"""
  "foobar" do
    false
  end

  "barbaz" do
    true
  end
  """
end
