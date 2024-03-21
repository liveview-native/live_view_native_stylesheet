defmodule ChildSheet do
  use LiveViewNative.Stylesheet, :mock
  @export true

  ~SHEET"""
  "foobar" do
    false
  end

  "barbaz" do
    true
  end
  """
end
