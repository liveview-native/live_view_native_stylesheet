defmodule LiveViewNative.Stylesheet.EncoderTest do
  use ExUnit.Case

  describe "encoder" do
    test "nil" do
      assert :json.encode(nil, &LiveViewNative.Stylesheet.Encoder.encode/2) == ~c(null)
    end
  end

  describe "formatter" do
    test "nil" do
      assert :json.format(nil, &LiveViewNative.Stylesheet.Encoder.format/3) == [~c(null), ?\n]
    end
  end
end
