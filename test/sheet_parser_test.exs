defmodule LiveViewNative.Stylesheet.SheetParserTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet.SheetParser

  alias LiveViewNative.Stylesheet.SheetParser

  @file_path __ENV__.file
  @file_name Path.basename(__ENV__.file) |> IO.inspect()
  @module __MODULE__

  ExUnit.Case.register_attribute(__MODULE__, :annotations)

  setup context do
    if context.registered.annotations do
      Application.put_env(:live_view_native_stylesheet, :annotations, true)

      on_exit(fn -> 
        Application.delete_env(:live_view_native_stylesheet, :annotations)
      end)
    end

    :ok
  end

  describe "SheetParser.parse" do

    @annotations true
    test "with a single literal as the class name, default target is implied" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {[
                  "color-red",
                  {:_target, [file: @file_name, line: 1, module: @module], Elixir}
                ],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(.red)"}
             ]
    end

    @annotations true
    test "the token end is ignored unless it is prefixed by a whitespace and suffixed by a whitespace or eos" do
      sheet = """
      "color-red" do
        rule-end
        end-rule
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {[
                  "color-red",
                  {:_target, [file: @file_name, line: 1, module: @module], Elixir}
                ],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "rule-end\nend-rule"}
             ]
    end

    @annotations true
    test "comments are ignored, unless they are part of the rules" do
      sheet = """
      # this is a comment that isn't included in the output
      "color-red" do
        color(.red)
        # this is a comment will not be stripped
      end
      # this is a comment that isn't included in the output
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {[
                  "color-red",
                  {:_target, [file: @file_name, line: 2, module: @module], Elixir}
                ],
                [
                  file: @file_name,
                  line: 3,
                  module: @module,
                  annotations: true
                ], "color(.red)\n# this is a comment will not be stripped"}
             ]
    end

    test "annotations can be controlled from the config" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      Application.put_env(:live_view_native_stylesheet, :annotations, false)
      result = SheetParser.parse(sheet, file: @file_path, module: @module)
      Application.delete_env(:live_view_native_stylesheet, :annotations)

      assert result == [
               {[
                  "color-red",
                  {:_target, [], Elixir}
                ], [annotations: false], "color(.red)"}
             ]
    end

    @annotations true
    test "can parse multiple class blocks" do
      sheet = """
      "color-red" do
        color(.red)
      end

      "color-blue" do

        color(.blue)
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {["color-red", {:_target, [file: @file_name, line: 1, module: @module], Elixir}],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(.red)"},
               {["color-blue", {:_target, [file: @file_name, line: 5, module: @module], Elixir}],
                [
                  file: @file_name,
                  line: 6,
                  module: @module,
                  annotations: true
                ], "\ncolor(.blue)"}
             ]
    end

    @annotations true
    test "with pattern matching in the class name, default target is implied" do
      sheet = """
      "color-" <> color_name do
        color(color: color_name)
        foobar
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

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
                ],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(color: color_name)\nfoobar"}
             ]
    end

    @annotations true
    test "with literal class name, target is defined" do
      sheet = """
      "color-red", target: :watch do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {["color-red", [file: @file_name, line: 1, module: @module, target: :watch]],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(.red)"}
             ]
    end

    @annotations true
    test "with pattern matching in the class name, target is defined" do
      sheet = """
      "color-" <> color_name, target: :tv do
        color(color: color_name)
        foobar
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

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
                ],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(color: color_name)\nfoobar"}
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
                     SheetParser.parse(sheet, file: @file_path, module: @module)
                   end

      sheet = """
      "color-red" <> do
        color(.red)
      end
      """

      assert_raise CompileError,
                   ~r|^test/sheet_parser_test.exs:1: Invalid class block:|,
                   fn ->
                     SheetParser.parse(sheet, file: @file_path, module: @module)
                   end
    end

    test "raises compile error when end is missing" do
      sheet = """
      "color-red" do
        color(.red)
      """

      assert_raise CompileError,
                   ~r|^test/sheet_parser_test.exs:2: Invalid class block:|,
                   fn ->
                     SheetParser.parse(sheet, file: @file_path, module: @module)
                   end
    end
  end
end
