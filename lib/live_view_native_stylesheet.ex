defmodule LiveViewNative.Stylesheet do
  defmodule Compiler do
    @callback compile(rules::binary) :: list
  end

  def compile(platform, rules) do
    with {:ok, platforms} <- Application.fetch_env(:live_view_native_stylesheet, :platforms),
    {:ok, compiler} <- Keyword.fetch(platforms, platform) do
      compiler.compile(rules)

    else
      :error -> "Make sure the compiler for platform `#{inspect(platform)}` is defined in your config for `:live_view_native_stylesheet`"
    end
  end

  defmacro __using__(platform) do
    quote do
      def compile(class_list, target: target) do
        Enum.reduce(class_list, %{}, fn(class_name, class_map) ->
          case class(class_name, target: target) do
            {:unmatched, msg} ->
              IO.puts(msg)
              class_map
            rules -> Map.put(class_map, class_name, LiveViewNative.Stylesheet.compile(unquote(platform), rules))
          end
        end)
      end
    end
  end

end
