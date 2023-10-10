defmodule LiveViewNative.Stylesheet.UtilsTest do
  use ExUnit.Case

  alias LiveViewNative.Stylesheet.Utils

  test "eval_quoted with string literal returns itself" do
    input = "foobar"

    assert Utils.eval_quoted(input) == input
  end

  test "eval_quoted with quoted statement returns expression" do
    input = {:<<>>, [], ["foobar"]}

    assert Utils.eval_quoted(input) == "foobar"
  end
end
