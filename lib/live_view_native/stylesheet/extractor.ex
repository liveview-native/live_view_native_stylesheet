defmodule LiveViewNative.Stylesheet.Extractor do
  @moduledoc false
  require Logger

  alias Phoenix.LiveView.Tokenizer

  # stolen/borrowed from Tailwind:
  # https://github.com/tailwindlabs/tailwindcss/blob/27c67fef4331954cea3290c51fafb6944eae9926/src/lib/defaultExtractor.js
  @broad_match_global_regexp [
    ~r/(?:\['([^'\s]+[^<>"'`\s:\\])')/,
    ~r/(?:\["([^"\s]+[^<>"'`\s:\\])")/,
    ~r/(?:\[`([^`\s]+[^<>"'`\s:\\])`)/,
    ~r/([^<>"'`\s]*\[\w*'[^"`\s]*'?\])/,
    ~r/([^<>"'`\s]*\[\w*"[^'`\s]*"?\])/,
    ~r/([^<>"'`\s]*\[\w*\('[^"'`\s]*'\)\])/,
    ~r/([^<>"'`\s]*\[\w*\("[^"'`\s]*"\)\])/,
    ~r/([^<>"'`\s]*\[\w*\('[^"`\s]*'\)\])/,
    ~r/([^<>"'`\s]*\[\w*\("[^'`\s]*"\)\])/,
    ~r/([^<>"'`\s]*\['[^"'`\s]*'\])/,
    ~r/([^<>"'`\s]*\["[^"'`\s]*"\])/,
    ~r/([^<>"'`\s]*\[[^<>"'`\s]*:'[^"'`\s]*'\])/,
    ~r/([^<>"'`\s]*\[[^<>"'`\s]*:"[^"'`\s]*"\])/,
    ~r/([^<>"'`\s]*\[[^"'`\s]+\][^<>"'`\s]*)/,
    ~r/([^<>"'`\s]*[^"'`\s:\\])/
  ]
  |> Enum.map(&Regex.source/1)
  |> Enum.join("|")
  |> Regex.compile!()

  @inner_match_global_regexp ~r/[^<>"'`\s.(){}[\]#=%]*[^<>"'`\s.(){}[\]#=%:]/

  @doc false
  def scan(content) do
    broad_matches = Regex.scan(@broad_match_global_regexp, content)
    inner_matches = Regex.run(@inner_match_global_regexp, content)

    [broad_matches, inner_matches]
  end

  @doc false
  def paths(sheet_path, format) do
    Application.get_env(:live_view_native_stylesheet, :content, [])
    |> Keyword.get(format, [])
    |> Enum.map(&convert_to_path(&1))
    |> List.flatten()
    |> Enum.map(&Path.wildcard(&1))
    |> List.flatten()
    |> Enum.reject(&(File.dir?(&1) || &1 == sheet_path))
  end

  defp default_style_attribute_parsers() do
    [
      neex: &style_attribute_template_parser/2,
      ex: &style_attribute_code_parser/2
    ]
  end

  defp found_style_attribute_parsers() do
    Application.get_env(:live_view_native_stylesheet, :attribute_parsers, [])
    |> Keyword.get(:style, [])
  end

  @doc false
  def run(%{paths: paths}) do
    files =
      paths
      |> Enum.map(&({File.read!(&1), &1}))

    class_names =
      files
      |> Enum.map(&scan(elem(&1, 0)))
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.reject(&rejector(&1))

    styles =
      files
      |> Enum.reduce([], fn({content, path}, acc) ->
        ext =
          path
          |> Path.extname()
          |> String.split(".")
          |> List.last()
          |> String.to_atom()

        parsers = default_style_attribute_parsers() ++ found_style_attribute_parsers()

        case Keyword.fetch(parsers, ext) do
          {:ok, func} -> acc ++ func.(content, path)
          :error -> acc
        end
      end)
      |> List.flatten()
      |> Enum.uniq()

    {class_names, styles}
  end

  defp style_attribute_template_parser(content, path) do
    parse_style(content, path)
  end

  defp style_attribute_code_parser(content, path) do
    content
    |> extract_templates()
    |> Enum.map(&parse_style(elem(&1, 0), path, elem(&1, 1)))
  end

  @doc false
  def extract_templates(content) do
    case Code.string_to_quoted(content) do
      {:ok, quoted} ->
        Macro.prewalk(quoted, [], fn
          {:sigil_LVN, _, [{:<<>>, annotations, [template]}, []]} =  node, acc -> {node, [{template, annotations} | acc]}
          node, acc -> {node, acc}
        end)
        |> elem(1)
      _ -> []
    end
  end

  @doc false
  def parse_style(template, path, opts \\ [])
  def parse_style(nil, _path, _opts), do: []
  def parse_style(template, path, opts) do
    {:ok, eex_nodes} = EEx.tokenize(template)

    indentation = Keyword.get(opts, :indentation, 0)
    state = Tokenizer.init(indentation, path, template, LiveViewNative.TagEngine)

    tokens =
      Enum.reduce(eex_nodes, [], fn
        {:text, tokens, meta}, tokens_acc ->
          text = List.to_string(tokens)
          meta = [line: meta.line, column: meta.column]

          {tokens, _context} = Tokenizer.tokenize(text, meta, [], :text, state)

          tokens_acc ++ tokens

        _eex_node, tokens_acc -> tokens_acc
      end)

    tokens
    |> Enum.reduce([], fn
      {type, _, attributes, _}, acc when type in [:tag, :slot, :local_component] ->
        parse_style_from_attributes(attributes, path) ++ acc
      _other, acc -> acc
    end)
    |> Enum.map(&({&1, path}))
  end

  defp parse_style_from_attributes([], _path), do: []
  defp parse_style_from_attributes(attributes, path) do
    Enum.reduce(attributes, [], fn
      {"style", {:string, value, _,}, _}, acc ->
        acc ++ decode_styles(value)
      {"style", {:expr, value, _}, _}, acc ->
        try do
          acc ++ (
            value
            |> Code.eval_string(assigns: %{})
            |> elem(0)
            |> List.wrap()
            |> Enum.map(&decode_styles(&1))
            |> List.flatten())
        rescue
          _e ->
            Logger.warning("attempted to use an @ variable in `style` attribute, not allowed\n#{path}")
            acc
        end
      _attr, acc -> acc
    end)
  end

  def decode_styles(value) do
    value
    |> String.to_charlist()
    |> tokenize_styles([], [])
  end

  defp tokenize_styles([], buffer, acc),
    do: append_buffer(buffer, acc)

  defp tokenize_styles(~c"&quot;" ++ t, buffer, acc) do
    tokenize_styles(t, [~c"\"" | buffer], acc)
  end

  defp tokenize_styles(~c";" ++ t, buffer, acc) do
    tokenize_styles(t, [], append_buffer(buffer, acc))
  end

  defp tokenize_styles([char | t], buffer, acc) do
    tokenize_styles(t, [char | buffer], acc)
  end

  defp append_buffer([], acc), do: acc
  defp append_buffer(buffer, acc) do
    buffer
    |> Enum.reverse()
    |> List.to_string()
    |> String.trim()
    |> case do
      "" -> acc
      value -> acc ++ [value]
    end
  end

  defp rejector(name) when is_binary(name) do
    name
    |> String.trim()
    |> Kernel.==("")
  end
  defp rejector(_other), do: false

  defp convert_to_path(pattern) when is_binary(pattern), do: pattern
  defp convert_to_path({otp_app, pattern}) when is_binary(pattern) do
    Mix.Project.deps_paths[otp_app]
    |> Path.join(pattern)
  end
  defp convert_to_path({otp_app, patterns}) when is_list(patterns) do
    Enum.map(patterns, &(convert_to_path({otp_app, &1})))
  end
end
