defmodule LiveViewNative.Stylesheet.SheetParserTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet.SheetParser

  alias LiveViewNative.Stylesheet.SheetParser

  @file_name __ENV__.file
  @module __MODULE__

  describe "SheetParser.parse" do
    test "with a single literal as the class name, default target is implied" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet, file: @file_name, module: @module)

      assert result == [
               {[
                  "color-red",
                  {:_target, [file: @file_name, line: 1, module: @module], Elixir}
                ], "color(.red)\n"}
             ]
    end

    test "annotations can be controlled from the config" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      Application.put_env(:live_view_native_stylesheet, :annotations, false)
      result = SheetParser.parse(sheet, file: @file_name, module: @module)
      Application.delete_env(:live_view_native_stylesheet, :annotations)

      assert result == [
               {[
                  "color-red",
                  {:_target, [], Elixir}
                ], "color(.red)\n"}
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

      result = SheetParser.parse(sheet, file: @file_name, module: @module)

      assert result == [
               {["color-red", {:_target, [file: @file_name, line: 1, module: @module], Elixir}],
                "color(.red)\n"},
               {["color-blue", {:_target, [file: @file_name, line: 5, module: @module], Elixir}],
                "\ncolor(.blue)\n"}
             ]
    end

    test "with pattern matching in the class name, default target is implied" do
      sheet = """
      "color-" <> color_name do
        color(color: color_name)
        foobar
      end
      """

      result = SheetParser.parse(sheet, file: @file_name, module: @module)

      assert result == [
               {[
                  {:<>,
                   [
                     file: @file_name,
                     line: 1,
                     module: @module,
                     context: Elixir,
                     imports: [{2, Kernel}]
                   ],
                   ["color-", {:color_name, [file: @file_name, line: 1, module: @module], Elixir}]},
                  {:_target, [file: @file_name, line: 1, module: @module], Elixir}
                ], "color(color: color_name)\nfoobar\n"}
             ]
    end

    test "with literal class name, target is defined" do
      sheet = """
      "color-red", target: :watch do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet, file: @file_name, module: @module)

      assert result == [
               {["color-red", [file: @file_name, line: 1, module: @module, target: :watch]],
                "color(.red)\n"}
             ]
    end

    test "with pattern matching in the class name, target is defined" do
      sheet = """
      "color-" <> color_name, target: :tv do
        color(color: color_name)
        foobar
      end
      """

      result = SheetParser.parse(sheet, file: @file_name, module: @module)

      assert result == [
               {[
                  {:<>,
                   [
                     file: @file_name,
                     line: 1,
                     module: @module,
                     context: Elixir,
                     imports: [{2, Kernel}]
                   ],
                   ["color-", {:color_name, [file: @file_name, line: 1, module: @module], Elixir}]},
                  [file: @file_name, line: 1, module: @module, target: :tv]
                ], "color(color: color_name)\nfoobar\n"}
             ]
    end

    test "raises compile error when block header is incorrect" do
      sheet = """
      "color-red" <> 1a do
        color(.red)
      end
      """

      assert_raise CompileError,
                   ~r|^test/sheet_parser_test.exs:1: Invalid class block:|,
                   fn ->
                     SheetParser.parse(sheet, file: @file_name, module: @module)
                   end

      sheet = """
      "color-red" <> do
        color(.red)
      end
      """

      assert_raise CompileError,
                   ~r|^test/sheet_parser_test.exs:1: Invalid class block:|,
                   fn ->
                     SheetParser.parse(sheet, file: @file_name, module: @module)
                   end
    end

    test "raises compile error when end is missing" do
      sheet = """
      "color-red" do
        color(.red)
      """

      assert_raise CompileError,
                   ~r|^test/sheet_parser_test.exs:3: Invalid class block:|,
                   fn ->
                     SheetParser.parse(sheet, file: @file_name, module: @module)
                   end
    end
  end
end
