defmodule LiveViewNative.Stylesheet.RulesHelpersTest do
  use ExUnit.Case

  alias LiveViewNative.Stylesheet.RulesHelpers

  test "to_atom" do
    assert RulesHelpers.to_atom("foobar") == :foobar
  end

  test "to_integer" do
    assert RulesHelpers.to_integer("123") == 123
  end

  test "to_float" do
    assert RulesHelpers.to_float("1.23") == 1.23
  end

  test "to_boolean" do
    # yes I know I could use assert without ==
    assert RulesHelpers.to_boolean("true") == true

    # yes I know I could use refute without ==
    assert RulesHelpers.to_boolean("false") == false
  end

  test "to_nil" do
    # yes I know I could use refute without ==
    assert RulesHelpers.to_nil("nil") == nil
  end

  test "camelize" do
    assert RulesHelpers.camelize("foo_bar") == "FooBar"
    assert RulesHelpers.camelize("foo-bar") == "FooBar"
  end

  test "underscore" do
    assert RulesHelpers.underscore("FooBar") == "foo_bar"
    assert RulesHelpers.underscore("foo-bar") == "foo_bar"
  end
end
