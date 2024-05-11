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
    ~LVN"""
    style="c-illegal"
    <Text style="c-string-2;c-string-3"/>
    <Text style="c-string-1;;; ;"/>
    """
  end
end
