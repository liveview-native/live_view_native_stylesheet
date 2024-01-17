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

    extracted_class_names = LiveViewNative.Stylesheet.Extractor.run()

    compiled_sheet_string = stylesheet_module.compile_string(extracted_class_names)
    compiled_sheet_ast = stylesheet_module.compile_ast(extracted_class_names)

    quote do
      # this function is mostly intended for debugging purposes
      # it isn't intended to be used directly in your application code
      def __stylsheet_ast__ do
        unquote(Macro.escape(compiled_sheet_ast))
      end

      def stylesheet(var!(assigns)) do
        sheet = unquote(compiled_sheet_string)
        var!(assigns) = Map.put(var!(assigns), :sheet, sheet)

        ~LVN"""
        <Style><%= @sheet %></Style>
        """
      end
    end
  end

  @doc """
  Embed the CSRF token for LiveView as a tag
  """
  def csrf_token(assigns) do
    csrf_token = Phoenix.Controller.get_csrf_token()

    assigns = Map.put(assigns, :csrf_token, csrf_token)

    ~LVN"""
    <csrf-token value={@csrf_token} />
    """
  end
end