defmodule Mix.Tasks.Lvn.Gen.StylesheetTest do
  use ExUnit.Case

  import Mix.Lvn.TestHelper

  alias Mix.Tasks.Lvn.Gen

  setup do
    Mix.Task.clear()
    :ok
  end

  test "generates the stylesheet for the request format into the `styles` directory", config do
    in_tmp_live_project config.test, fn ->
      Gen.Stylesheet.run(["mock", "App"])
      assert_file "lib/live_view_native_stylesheet_web/styles/app.mock.ex"
    end
  end

  test "will raise with message if invalid format is given", config do
    in_tmp_live_project config.test, fn ->
      assert_raise(Mix.Error, fn() ->
        Gen.Stylesheet.run(["other"])
      end)
      refute_file "lib/live_view_native_stylesheet_web/styles/app.mock.ex"
    end
  end
end
