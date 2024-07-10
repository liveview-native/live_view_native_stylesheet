defmodule LiveViewNative.Stylesheet.ExtractorTest do
  use ExUnit.Case

  def parse_style(template, path) do
    template
    |> LiveViewNative.Stylesheet.Extractor.parse_style(path)
    |> Enum.map(&(elem(&1, 0)))
  end

  describe "style attribute parser" do
    test "can parse out the style attribute from a tag" do
      template = """
      <Text style="a"></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "can parse multiple definitions" do
      template = """
      <Text style="a"></Text>
      <Text style="b"></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "will ignore illegal matches" do
      template = """
      style="illegal"
      <Text style="a"></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "will parse the attribute value" do
      template = """
      <Text style="a;b"></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "will collapse empty segments" do
      template = """
      <Text style="a;b ;; ;;"></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "parse ignore whitespace" do
      template = """
      <Text style = "a" ></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "parse string from bracket" do
      template = """
      <Text style={"a"}></Text>
      """

      assert parse_style(template, "nofile") == ["a"]
    end

    test "parse list of strings from bracket" do
      template = """
      <Text style={[
        "a",
        "b"
      ]}></Text>
      """

      assert parse_style(template, "nofile") == ["a", "b"]
    end

    test "styles that have quotes are properly encoded" do
      template = """
      <Text style={[
        ~S'attr("test")'
      ]}></Text>
      """

      assert parse_style(template, "nofile") == [~S'attr("test")']
    end
  end

  describe "extract_templates" do
    test "when valid Elixir code with no LVN template" do
      code = ~S'''
        defmodule TestCode do
        end
      '''

      result = LiveViewNative.Stylesheet.Extractor.extract_templates(code)

      assert result == []
    end

    test "when valid Elixir code with LVN template" do
      code = ~S'''
        defmodule TestCode do
          def render(_, _) do
             ~LVN"""
             <Text>Hello, world!</Text>
             """
          end
        end
      '''

      result = LiveViewNative.Stylesheet.Extractor.extract_templates(code)

      assert result == [{"<Text>Hello, world!</Text>\n", [indentation: 7, line: 3]}]
    end

    test "when valid Elixir code with multiple LVN template" do
      code = ~S'''
        defmodule TestCode do
          def render(_, _) do
             ~LVN"""
             <Text>Hello, world!</Text>
             """
          end

          def other(_, _)
            ~LVN"""
            <Text>Bye!</Text>
            """
          end
      '''

      result = LiveViewNative.Stylesheet.Extractor.extract_templates(code)

      assert result == [{"<Text>Bye!</Text>\n", [indentation: 6, line: 9]}, {"<Text>Hello, world!</Text>\n", [indentation: 7, line: 3]}]
    end

    test "when invalid Elixir code" do
      code = ~S'''
        <Text>Hello!</Text>
      '''

      result = LiveViewNative.Stylesheet.Extractor.extract_templates(code)

      assert result == []
    end
  end
end
