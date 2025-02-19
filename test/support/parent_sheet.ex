defmodule ParentSheet do
  use LiveViewNative.Stylesheet, :mock
  @import ChildSheet
  @safe_list ~w{parent-safe}

  ~SHEET"""
  "foobar" do
    true
  end

  "parent-safe" do
    parent-safe
  end
  """
end
