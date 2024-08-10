defmodule Mix.LiveViewNative.Stylesheet.CodeGen.PatchTest do
  use ExUnit.Case

  alias Mix.LiveViewNative.Stylesheet.CodeGen.Patch

  describe "patch config codegen scenarios" do
    test "when :live_view_native_stylesheet config exists the :plugins list is updated and duplicates are removed" do
      source = """
        config :live_view_native_stylesheet,
          content: [
            other: [
              "lib/**/other/*"
            ]
          ],
          output: "priv/static/other_assets"
        """

      data = [:mock]

      {:ok, result} = Patch.patch_stylesheet_config(%{}, data, source, "config/config.exs")

      assert result =~ """
        config :live_view_native_stylesheet,
          content: [
            mock: [
              "lib/**/mock/*",
              "lib/**/*mock*"
            ],
            other: [
              "lib/**/other/*"
            ]
          ],
          output: "priv/static/other_assets"
        """
    end
  end

  describe "patch dev codgen scenarios" do
    test "when :live_view_native_stylesheet exists, don't replace" do
      source = """
        config :live_view_native_stylesheet,
          annotations: true
      """

      {:ok, result} = Patch.patch_stylesheet_dev(%{}, nil, source, "config/dev.exs")

      assert result == source
    end
  end

end
