defmodule ChildSheet do
  use LiveViewNative.Stylesheet, :mock
  @export true
  @safe_list ~w{child-safe}

  ~SHEET"""
  "foobar" do
    false
  end

  "barbaz" do
    true
  end

  "child-safe" do
    child-safe
  end
  """
end
