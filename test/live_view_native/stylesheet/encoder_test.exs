defmodule LiveViewNative.Stylesheet.EncoderTest do
  use ExUnit.Case

  test "nil" do
    assert :json.encode(nil, &LiveViewNative.Stylesheet.Encoder.encode/2) == ~c(null)
  end
end
