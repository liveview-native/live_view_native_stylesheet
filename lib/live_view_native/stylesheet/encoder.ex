defmodule LiveViewNative.Stylesheet.Encoder do
  def format({term, annotations, arguments}, encoder, state) do
    annotations = Enum.into(annotations, %{}, &(&1))
    format([term, annotations, arguments], encoder, state)
  end

  def format({name, value}, encoder, state) when is_atom(name),
    do: :json.format_value(%{{name, value}}, encoder, state)

  def format(atom, encoder, state) when is_atom(atom) do
    cond do
      Code.ensure_loaded?(atom) ->
        "Elixir." <> module = Atom.to_string(atom)
        :json.format_value(module, encoder, state)
      true -> :json.format_value(atom, encoder, state)
    end
  end

  def format(dynamic, encoder, state),
    do: :json.format_value(dynamic, encoder, state)

  def encode({term, annotations, arguments}, encoder) do
    annotations = Enum.into(annotations, %{}, &(&1))
    :json.encode_list([term, annotations, arguments], encoder)
  end

  def encode({name, value}, encoder) when is_atom(name),
    do: :json.encode_map(%{{name, value}}, encoder)


  def encode(nil, _encoder),
    do: ~c(null)

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
