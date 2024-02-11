defmodule LiveViewNative.Stylesheet.Component do
  @moduledoc """
  Component functions for stylesheets
  """
  import LiveViewNative.Component, only: [sigil_LVN: 2]

  @doc """
  Embeds a stylehseet within the component module

  Compiled stylesheet can be called with the
  functional component `stylesheet/1`

  ```heex
  <.stylesheet />
  ```
  """
  defmacro embed_stylesheet(stylesheet_module) do
    stylesheet_module = Macro.expand(stylesheet_module, __CALLER__)

    {files, class_names} = LiveViewNative.Stylesheet.Extractor.run(stylesheet_module)

    compiled_sheet_string = stylesheet_module.compile_string(class_names)
    compiled_sheet_ast = stylesheet_module.compile_ast(class_names)

    quote do
      for file <- unquote(files) do
        @external_resource file
      end

      # this function is mostly intended for debugging purposes
      # it isn't intended to be used directly in your application code
      def __stylesheet_ast__ do
        unquote(Macro.escape(compiled_sheet_ast))
      end

      def stylesheet(var!(assigns)) do
        sheet =
          unquote(compiled_sheet_string)
          |> Phoenix.HTML.raw()

        var!(assigns) = Map.put(var!(assigns), :sheet, sheet)

        ~LVN"""
        <Style><%= @sheet %></Style>
        """
      end
    end
  end
end
