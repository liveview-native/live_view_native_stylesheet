defmodule LiveViewNative.Stylesheet.SheetParserTest do
  use ExUnit.Case
  doctest LiveViewNative.Stylesheet.SheetParser

  alias LiveViewNative.Stylesheet.SheetParser

  @file_path __ENV__.file
  @file_name Path.basename(__ENV__.file)
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
    test "with a single literal as the class name" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {[
                  "color-red"
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
                  "color-red"
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
                  "color-red"
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

      assert result == [{["color-red"], [line: 2, annotations: false], "color(.red)"}]
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
               {["color-red"],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(.red)"},
               {["color-blue"],
                [
                  file: @file_name,
                  line: 6,
                  module: @module,
                  annotations: true
                ], "\ncolor(.blue)"}
             ]
    end

    @annotations true
    test "with pattern matching in the class name" do
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
                     context: nil,
                     imports: [{2, Kernel}]
                   ],
                   ["color-", {:color_name, [file: @file_name, line: 1, module: @module], nil}]}
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
    test "with literal class name" do
      sheet = """
      "color-red" do
        color(.red)
      end
      """

      result = SheetParser.parse(sheet, file: @file_path, module: @module)

      assert result == [
               {["color-red"],
                [
                  file: @file_name,
                  line: 2,
                  module: @module,
                  annotations: true
                ], "color(.red)"}
             ]
    end
  end

  describe "error reporting" do
    setup do
      # Disable ANSI so we don't have to worry about colors
      Application.put_env(:elixir, :ansi_enabled, false)
      on_exit(fn -> Application.put_env(:elixir, :ansi_enabled, true) end)
    end

    test "raises compile error when block header has invalid variable" do
      sheet = """
      "color-red" <> 1a do
        color(.red)
      end
      """

      error =
        assert_raise SyntaxError,
                     fn ->
                       SheetParser.parse(sheet, file: @file_path, module: @module)
                     end

      error_prefix =
        """
        Invalid class block:
          |
        1 | "color-red" <> 1a do
          |                ^^
          |

        expected a variable
        """
        |> String.trim()

      assert String.trim(error.description) == error_prefix
    end

    test "raises compile error when block header is unexpectedly missing a varaible" do
      sheet = """
      "color-red" <> do
        color(.red)
      end
      """

      error =
        assert_raise SyntaxError,
                     fn ->
                       SheetParser.parse(sheet, file: @file_path, module: @module)
                     end

      error_prefix =
        """
        Invalid class block:
          |
        1 | "color-red" <> do
          | ^^^^^^^^^^^
          |

        invalid class header
        """
        |> String.trim()

      assert String.trim(error.description) == error_prefix
    end

    test "class names should not contain spaces" do
      sheet = """
      "rule containing end" do
        color(.red)
      end
      """

      error =
        assert_raise SyntaxError,
                     fn ->
                       SheetParser.parse(sheet, file: @file_path, module: @module)
                     end

      error_prefix =
        """
        Invalid class block:
          |
        1 | "rule_containing end" do
          |      ^
          |

        Whitespace is not allowed in the class name, but got ‘ ’
        """
        |> String.trim()

      assert String.trim(error.description) == error_prefix
    end

    test "raises compile error when end is missing" do
      sheet = """
      "color-red" do
        color(.red)
      """

      error =
        assert_raise SyntaxError,
                     fn ->
                       SheetParser.parse(sheet, file: @file_path, module: @module)
                     end

      error_prefix =
        """
          Invalid class block:
          |
        2 |   color(.red)
          |
          |

        expected an end
        """
        |> String.trim()

      assert String.trim(error.description) == error_prefix
    end
  end
end
