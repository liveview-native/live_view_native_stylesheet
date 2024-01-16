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
end