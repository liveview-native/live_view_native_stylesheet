defmodule LiveViewNative.Stylesheet.SheetParserTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet.SheetParser

  alias LiveViewNative.Stylesheet.SheetParser

  describe "SheetParser.parse" do
    test "with a single literal as the class name, default target is implied" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet)

      assert result == [
        {["color-red", {:_target, [], Elixir}], "color(.red)\n"}
      ]
    end

    test "can parse multiple class blocks" do
      sheet = """
      "color-red" do
        color(.red)
      end

      "color-blue" do
        color(.blue)
      end
      """

      result = SheetParser.parse(sheet)

      assert result == [
        {["color-red", {:_target, [], Elixir}], "color(.red)\n"},
        {["color-blue", {:_target, [], Elixir}], "color(.blue)\n"}
      ]
    end

    test "with pattern matching in the class name, default target is implied" do
      sheet = """
      "color-" <> color_name do
        color(color: color_name)
        foobar
      end
      """

      result = SheetParser.parse(sheet)

      assert result == [
        {[{:<>, [context: Elixir, imports: [{2, Kernel}]], ["color-", {:color_name, [], Elixir}]}, {:_target, [], Elixir}], "color(color: color_name)\nfoobar\n"}
      ]
    end

    test "with literal class name, target is defined" do

      sheet = """
      "color-red", target: :watch do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet)

      assert result == [
        {["color-red", [target: :watch]], "color(.red)\n"}
      ]
    end

    test "with pattern matching in the class name, target is defined" do
      sheet = """
      "color-" <> color_name, target: :tv do
        color(color: color_name)
        foobar
      end
      """

      result = SheetParser.parse(sheet)

      assert result == [
        {[{:<>, [context: Elixir, imports: [{2, Kernel}]], ["color-", {:color_name, [], Elixir}]}, [target: :tv]], "color(color: color_name)\nfoobar\n"}
      ]
    end
  end
end
