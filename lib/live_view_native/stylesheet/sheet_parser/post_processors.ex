defmodule LiveViewNative.Stylesheet.SheetParser.PostProcessors do
  def wrap_in_tuple(rest, args, context, _line, _offset) do
    {rest, [List.to_tuple(Enum.reverse(args))], context}
  end

  def block_open_with_variable_to_ast(rest, [variable, string], context, _line, _offset) do
    {rest,
     [
       {:<>, [context: Elixir, imports: [{2, Kernel}]], [string, variable]}
     ], context}
  end

  def block_open_to_ast(rest, [class_name], context, _line, _offset) do
    {rest, [[class_name, {:_target, [], Elixir}]], context}
  end

  def block_open_to_ast(rest, [key_value_pairs, class_name], context, _line, _offset) do
    {rest, [[class_name, key_value_pairs]], context}
  end

  def tag_as_elixir_code(rest, [quotable], context, _line, _offset) do
    {rest, [{Elixir, [], quotable}], context}
  end

  def to_elixir_variable_ast(rest, [variable_name], context, _line, _offset) do
    {rest, [{String.to_atom(variable_name), [], Elixir}], context}
  end

  def to_keyword_tuple_ast(rest, [arg1, arg2], context, _line, _offset) do
    {rest, [{String.to_atom(arg2), arg1}], context}
  end

  def to_function_call_ast(rest, args, context, _line, _offset) do
    [ast_name | other_args] = Enum.reverse(args)

    {rest, [{String.to_atom(ast_name), [], other_args}], context}
  end
end
