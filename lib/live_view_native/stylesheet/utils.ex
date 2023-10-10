defmodule LiveViewNative.Stylesheet.Utils do
  def eval_quoted(expr) when is_binary(expr), do: expr
  def eval_quoted({:<<>>, _, [expr]}), do: expr
end
