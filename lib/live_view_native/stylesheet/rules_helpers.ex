defmodule LiveViewNative.Stylesheet.RulesHelpers do
  def to_atom(expr) when is_binary(expr), do: String.to_atom(expr)

  def to_integer(expr) when is_binary(expr) do
    Integer.parse(expr) |> elem(0)
  end

  def to_float(expr) when is_binary(expr) do
    Float.parse(expr) |> elem(0)
  end

  def to_number(expr) when is_binary(expr) do
    try do
      {integer, ""} = Integer.parse(expr)
      integer
    rescue
      _ ->
        to_float(expr)
    end
  end

  def to_boolean("true"), do: true
  def to_boolean("false"), do: false

  def to_nil("nil"), do: nil

  # stolen from Elixir's Macro module
  # License: https://github.com/elixir-lang/elixir/blob/main/LICENSE
  def camelize(string)

  def camelize(""), do: ""
  def camelize(<<?_, t::binary>>), do: camelize(t)
  def camelize(<<h, t::binary>>), do: <<to_upper_char(h)>> <> do_camelize(t)

  defp do_camelize(<<?_, ?_, t::binary>>), do: do_camelize(<<?_, t::binary>>)

  defp do_camelize(<<?_, h, t::binary>>) when h >= ?a and h <= ?z,
    do: <<to_upper_char(h)>> <> do_camelize(t)

  defp do_camelize(<<?-, h, t::binary>>) when h >= ?a and h <= ?z,
    do: <<to_upper_char(h)>> <> do_camelize(t)

  defp do_camelize(<<?_, h, t::binary>>) when h >= ?0 and h <= ?9, do: <<h>> <> do_camelize(t)
  defp do_camelize(<<?_>>), do: <<>>
  defp do_camelize(<<?/, t::binary>>), do: <<?.>> <> camelize(t)
  defp do_camelize(<<h, t::binary>>), do: <<h>> <> do_camelize(t)
  defp do_camelize(<<>>), do: <<>>

  defp to_upper_char(char) when char >= ?a and char <= ?z, do: char - 32
  defp to_upper_char(char), do: char

  defp to_lower_char(char) when char >= ?A and char <= ?Z, do: char + 32
  defp to_lower_char(char), do: char

  # stolen from Elixir's Macro module
  # License: https://github.com/elixir-lang/elixir/blob/main/LICENSE
  def underscore(atom_or_string)

  def underscore(<<h, t::binary>>) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  def underscore("") do
    ""
  end

  defp do_underscore(<<h, t, rest::binary>>, _)
       when h >= ?A and h <= ?Z and not (t >= ?A and t <= ?Z) and not (t >= ?0 and t <= ?9) and
              t != ?. and t != ?_ do
    <<?_, to_lower_char(h), t>> <> do_underscore(rest, t)
  end

  defp do_underscore(<<h, t::binary>>, prev)
       when h >= ?A and h <= ?Z and not (prev >= ?A and prev <= ?Z) and prev != ?_ do
    <<?_, to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<?., t::binary>>, _) do
    <<?/>> <> underscore(t)
  end

  defp do_underscore(<<?-, t::binary>>, _) do
    <<?_>> <> underscore(t)
  end

  defp do_underscore(<<h, t::binary>>, _) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<>>, _) do
    <<>>
  end
end
