defmodule LiveViewNative.Stylesheet.SheetParser.PostProcessors do
  import LiveViewNative.Stylesheet.SheetParser.Parser.Annotations

  def mark_line(rest, args, context, {line, _offset}, _byte_offset, name) do
    {rest, args, Map.put(context, name, line)}
  end

  def unmark_line(rest, args, context, _line, _byte_offset, name) do
    {rest, args, Map.delete(context, name)}
  end

  def wrap_in_tuple(rest, args, context, _line, _byte_offset) do
    {rest, [List.to_tuple(Enum.reverse(args))], context}
  end

  def block_open_with_variable_to_ast(rest, [variable, string], context, {line, _offset}, _offset) do
    {rest,
     [
       {:<>, context_to_annotation(context, line) ++ [context: Elixir, imports: [{2, Kernel}]],
        [string, variable]}
     ], context}
  end

  def block_open_to_ast(rest, [class_name], context, {line, _offset}, _byte_offset) do
    {rest,
     [
       [
         class_name,
         {:_target, context_to_annotation(context, line), Elixir}
       ]
     ], context}
  end

  def block_open_to_ast(rest, [opts, class_name], context, {line, _}, _byte_offset) do
    {rest, [[class_name, context_to_annotation(context, line) ++ opts]], context}
  end

  def tag_as_elixir_code(rest, [quotable], context, {line, _offset}, _byte_offset) do
    {rest,
     [{Elixir, context_to_annotation(context, context[:open_elixir_code] || line), quotable}],
     Map.delete(context, :open_elixir_code)}
  end

  def to_elixir_variable_ast(rest, [variable_name], context, {line, _offset}, _byte_offset) do
    {rest, [{String.to_atom(variable_name), context_to_annotation(context, line), Elixir}],
     context}
  end

  def to_keyword_tuple_ast(rest, [arg1, arg2], context, _line, _byte_offset) do
    {rest, [{String.to_atom(arg2), arg1}], context}
  end

  def to_function_call_ast(rest, args, context, {line, _offset}, _byte_offset) do
    [ast_name | other_args] = Enum.reverse(args)

    {rest,
     [
       {String.to_atom(ast_name),
        context_to_annotation(context, context[:open_function_line] || line), other_args}
     ], Map.delete(context, :open_function_line)}
  end
end
