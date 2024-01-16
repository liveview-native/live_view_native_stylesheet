defmodule LiveViewNative.Stylesheet.Component do
  @moduledoc """
  Component functions for stylesheets
  """
  import LiveViewNative.Component, only: [sigil_LVN: 2]

  @doc """
  Embed the stylesheet within a template

  Take a module as an attribute value:

  ```heex
  <.embed_stylsheet module={MyAppWeb.HomeSheet} />
  ```
  """
  def embed_stylesheet(%{module: module} = assigns) do
    sheet =
      module
      |> LiveViewNative.Stylesheet.file_path()
      |> File.read!()

    assigns = Map.put(assigns, :sheet, sheet)

    ~LVN"""
    <Style><%= @sheet %></Style>
    """
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