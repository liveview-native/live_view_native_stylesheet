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

    test "Parent will inherit and combine child safe lists" do
      styles = File.read!("priv/static/assets/parent_sheet.styles") |> :json.decode()
      assert styles["child-safe"] == ["child-safe"]
      assert styles["parent-safe"] == ["parent-safe"]
    end
  end
end
