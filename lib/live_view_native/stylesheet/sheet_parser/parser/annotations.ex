defmodule LiveViewNative.Stylesheet.SheetParser.Parser.Annotations do
  alias LiveViewNative.Stylesheet.SheetParser.Parser.Context
  # Helpers

  def context_to_annotation(%{context: %Context{annotations: true} = context}, line) do
    source = Enum.at(context.source_lines, line - 1 , "")
    [file: context.file, line: line, module: context.module, source: String.trim(source)]
  end

  def context_to_annotation(_, _) do
    []
  end
end
