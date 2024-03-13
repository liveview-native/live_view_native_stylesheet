defmodule LiveViewNative.Stylesheet.Extractor do
  @moduledoc false

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

  def scan(content) do
    broad_matches = Regex.scan(@broad_match_global_regexp, content)
    inner_matches = Regex.run(@inner_match_global_regexp, content)

    [broad_matches, inner_matches]
  end

  def paths(sheet_path, format) do
    Application.get_env(:live_view_native_stylesheet, :content, [])
    |> Keyword.get(format, [])
    |> Enum.map(&convert_to_path(&1))
    |> Enum.map(&Path.wildcard(&1))
    |> List.flatten()
    |> Enum.reject(&(File.dir?(&1) || &1 == sheet_path))
  end

  def run(%{paths: paths}) do
    paths
    |> Enum.map(&File.read!(&1))
    |> Enum.map(&scan(&1))
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.reject(&rejector(&1))
  end

  defp rejector(name) when is_binary(name) do
    name
    |> String.trim()
    |> Kernel.==("")
  end
  defp rejector(_other), do: false

  defp convert_to_path(pattern) when is_binary(pattern), do: pattern
  defp convert_to_path({otp_app, pattern}) do
    Mix.Project.deps_paths[otp_app]
    |> Path.join(pattern)
  end
end
