defmodule LiveViewNative.Stylesheet.SheetParser.Parser.Annotations do
  alias LiveViewNative.Stylesheet.SheetParser.Parser.Context
  # Helpers

  def context_to_annotation(%{context: %Context{} = context}, line) do
    context_to_annotation(context, line)
  end

  if Mix.env() != :prod do
    def context_to_annotation(%Context{} = context, line) do
      [file: context.file, line: line, module: context.module]
    end
  else
    def context_to_annotation(context, line) do
      []
    end
  end
end
