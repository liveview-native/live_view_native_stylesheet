defmodule LiveViewNative.Stylesheet.SheetParser.Parser.Annotations do
  @moduledoc false
  alias LiveViewNative.Stylesheet.SheetParser.Parser.Context
  # Helpers

  def context_to_annotation(%{context: %Context{annotations: true} = context}, line) do
    [file: context.file, line: line, module: context.module]
  end

  def context_to_annotation(_, _) do
    []
  end
end
