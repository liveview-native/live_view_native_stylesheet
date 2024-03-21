defmodule ParentSheet do
  use LiveViewNative.Stylesheet, :mock
  @import ChildSheet

  ~SHEET"""
  "foobar" do
    true
  end
  """
end
