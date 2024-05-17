defmodule MockRenderComponent do
  use LiveViewNative.Component, format: :mock

  def render(assigns, _) do
    ~LVN"""
    <Text style="c-string-1"/>
    <Text style={"c-bracket-1"}/>
    <Text style={"c-bracket-\"2\""}/>
    <Text style={[
    "c-bracket-3",
    ~S(c-bracket-4)
    ]}/>
    """
  end

  def modal(assigns) do
    assigns = Map.put(assigns, :style, "c-assign-1")

    ~LVN"""
    style="c-illegal"
    <Text style="c-string-2;c-string-3"/>
    <Text style="c-string-1;;; ;"/>
    <.image style="c-local-component-string-1">
      <:success style="c-slot-string-1"/>
    </.image>
    <Text style={@style}/>
    """
  end

  def image(assigns) do
    ~LVN"""
    <image></image>
    """
  end
end
