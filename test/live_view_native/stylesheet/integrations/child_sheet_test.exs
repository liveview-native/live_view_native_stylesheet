defmodule ChildSheetTest do
  use ExUnit.Case

  describe "stylesheet output" do
    test "will override the child's class definition" do
      assert ParentSheet.class("foobar") == ["true"]
    end

    test "will inherit the child sheet's class definitions" do
      assert ParentSheet.class("barbaz") == ["true"]
    end

    test "should not compile to file" do
      refute File.exists?("priv/static/assets/child_sheet.styles")
    end
  end
end
