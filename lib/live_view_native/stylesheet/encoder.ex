defmodule LiveViewNative.Stylesheet.Encoder do
  def encode({term, annotations, arguments}, encoder) do
    annotations = Enum.into(annotations, %{}, &(&1))
    :json.encode_list([term, annotations, arguments], encoder)
  end

  def encode(atom, encoder) when is_atom(atom) do
    cond do
      Code.ensure_loaded?(atom) ->
        "Elixir." <> module = Atom.to_string(atom)
        :json.encode_binary(module)
      true -> :json.encode_atom(atom, encoder)
    end
  end

  def encode(dynamic, encoder),
    do: :json.encode_value(dynamic, encoder)
end
