defmodule MockClient do
  use LiveViewNative,
    format: :mock,
    stylesheet: __MODULE__,
    stylesheet_rules_parser: MockRulesParser,
    component: MockComponent

  defmacro __using__(_) do
    quote do
      @special true
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def special do
        %{"special" => @special}
      end
    end
  end
end
