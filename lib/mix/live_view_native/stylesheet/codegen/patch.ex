defmodule Mix.LiveViewNative.Stylesheet.CodeGen.Patch do
  @moduledoc false

  import Mix.LiveViewNative.Context, only: [
    compile_string: 1,
    last?: 2
  ]

  import Mix.LiveViewNative.CodeGen, only: [
    build_patch: 2
  ]

  import Mix.LiveViewNative.CodeGen.Patch, only: [
    fail_msg: 5,
    config_matcher: 1,
  ]

  alias Mix.LiveViewNative.CodeGen
  alias Sourceror.Zipper

  @doc false
  def patch_stylesheet_config(_context, formats, source, path) do
    formats =
      formats
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.sort()

    change = """

    config :live_view_native_stylesheet,
      content: [<%= for format <- formats do %>
        <%= format %>: [
          "lib/**/<%= format %>/*",
          "lib/**/*<%= format %>*"
        ]<%= unless last?(formats, format) do %>,<% end %><% end %>
      ],
      output: "priv/static/assets"
    """
    |> compile_string()

    fail_msg = fail_msg("inject", "code", path, change, &doc_ref/0)

    CodeGen.patch(source, change, merge: &merge_stylesheet_config/2, inject: {:after, {:last, &config_matcher/1}}, fail_msg: fail_msg, path: path)
  end

  defp merge_stylesheet_config(source, change) do
    quoted_change = Sourceror.parse_string!(change)

    source
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Zipper.find(&match?({:config, _, [{:__block__, _, [:live_view_native_stylesheet]} | _]}, &1))
    |> case do
      nil -> :error
      found ->
        Zipper.find(found, &match?({{:__block__, _, [:content]}, _}, &1))
        |> case do
          nil -> :error
          %{node: {{:__block__, _, [:content]}, quoted_source_block}} ->
            {:config, _, [_, [{_, quoted_change_block} | _]]} = quoted_change
            range = Sourceror.get_range(quoted_source_block)
            source_list = Code.eval_quoted(quoted_source_block) |> elem(0)
            change_list = Code.eval_quoted(quoted_change_block) |> elem(0)

            formats =
              (source_list ++ change_list)
              |> Enum.uniq_by(fn({format, _}) -> format end)
              |> Enum.sort_by(fn({format, _}) -> format end)

            change = """
              [<%= for {format, patterns}  <- formats do %>
                <%= format %>: [<%= for pattern <- patterns do %>
                  <%= inspect pattern %><%= unless last?(patterns, pattern) do %>,<% end %><% end %>
                ]<%= unless last?(formats, {format, patterns}) do %>,<% end %><% end %>
              ]
              """
              |> compile_string()
              |> String.trim()

            [build_patch(range, change)]
        end
    end
  end

  @doc false
  def patch_stylesheet_dev(_context, _data, source, path) do
    change = """

    config :live_view_native_stylesheet,
      annotations: true,
      pretty: true
    """
    |> compile_string()

    fail_msg = fail_msg("inject", "code", path, change, &doc_ref/0)

    CodeGen.patch(source, change, merge: &merge_stylesheet_dev/2, inject: :eof, fail_msg: fail_msg, path: path)
  end

  defp merge_stylesheet_dev(source, _change) do
    source
    |> Sourceror.parse_string!()
    |> Zipper.zip()
    |> Zipper.find(&match?({:config, _, [{:__block__, _, [:live_view_native_stylesheet]}, options]} when is_list(options), &1))
    |> case do
      nil -> :error
      _found ->
        []
    end
  end

  @doc false
  def doc_ref() do
    version = Application.spec(:live_view_native_stylesheet)[:vsn]

    """
    Please reference the documentation for more information on configuring LiveView Native Stylesheet:
    https://hexdocs.pm/live_view_native_stylesheet/#{version}/LiveViewNative.Stylesheet.html#module-configuration
    """
  end
end
