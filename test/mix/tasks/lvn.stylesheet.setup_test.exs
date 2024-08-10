defmodule Mix.Tasks.Lvn.Stylesheet.SetupTest do
  use ExUnit.Case

  import Mix.Lvn.TestHelper
  import ExUnit.CaptureIO

  @templates Path.join(File.cwd!(), "test/mix/tasks/templates")

  alias Mix.Tasks.Lvn.Stylesheet.Setup.{Config, Gen}

  setup do
    Mix.Task.clear()
    :ok
  end

  describe "when a single app" do
    test "generates the stylesheet for each plugin and injects config", config do
      in_tmp_live_project config.test, fn ->
        File.mkdir_p!("config")
        File.write!("config/config.exs", File.read!(Path.join(@templates, "config")))
        File.write!("config/dev.exs", File.read!(Path.join(@templates, "dev")))

        capture_io("y\ny\n", fn ->
          Config.run([])
        end)

        Gen.run([])

        assert_file "lib/live_view_native_stylesheet_web/styles/app.mock.ex"

        assert_file "config/config.exs", fn file ->
          assert file =~ """
            config :live_view_native_stylesheet,
              content: [
                mock: [
                  "lib/**/mock/*",
                  "lib/**/*mock*"
                ]
              ],
              output: "priv/static/assets"
            """

          assert file =~ """
            config :mime, :types, %{
              "text/styles" => ["styles"]
            }
            """
        end

        assert_file "config/dev.exs", fn file ->
          assert file =~ """
            config :live_view_native_stylesheet, LiveViewNativeStylesheetWeb.Endpoint,
              live_reload: [
                patterns: [
                  ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
                  ~r"priv/gettext/.*(po)$",
                  ~r"lib/live_view_native_stylesheet_web/(controllers|live|components)/.*(ex|heex)$",
                  ~r"lib/live_view_native_stylesheet_web/styles/*.ex$",
                  ~r"priv/static/*.styles$"
                ]
              ]
            """

          assert file =~ """
            config :live_view_native_stylesheet,
              annotations: true,
              pretty: true
            """
        end
      end
    end
  end

  describe "when an umbrella app" do
    test "generates the `Native` module into the project's lib directory", config do
      in_tmp_live_umbrella_project config.test, fn ->
        File.cd!("live_view_native_stylesheet_web", fn ->
          File.mkdir_p!("config")
          File.write!("config/config.exs", File.read!(Path.join(@templates, "config")))
          File.write!("config/dev.exs", File.read!(Path.join(@templates, "dev")))

          capture_io("y\ny\n", fn ->
            Config.run([])
          end)

          Gen.run([])

          assert_file "lib/live_view_native_stylesheet_web/styles/app.mock.ex"

          assert_file "config/config.exs", fn file ->
            assert file =~ """
              config :live_view_native_stylesheet,
                content: [
                  mock: [
                    "lib/**/mock/*",
                    "lib/**/*mock*"
                  ]
                ],
                output: "priv/static/assets"
              """
          end

          assert_file "config/dev.exs", fn file ->
            assert file =~ """
              config :live_view_native_stylesheet, LiveViewNativeStylesheetWeb.Endpoint,
                live_reload: [
                  patterns: [
                    ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
                    ~r"priv/gettext/.*(po)$",
                    ~r"lib/live_view_native_stylesheet_web/(controllers|live|components)/.*(ex|heex)$",
                    ~r"lib/live_view_native_stylesheet_web/styles/*.ex$",
                    ~r"priv/static/*.styles$"
                  ]
                ]
              """

            assert file =~ """
              config :live_view_native_stylesheet,
                annotations: true,
                pretty: true
              """
          end
        end)
      end
    end
  end

end
