  # TODO: Remove when OTP 27 is the minimum release OTP for Elixir
  defmodule MinimumOTPError do
    @moduledoc false
    defexception [:message]
  end

  min_otp = 27

  otp_version =
    :erlang.system_info(:otp_release)
    |> List.to_string()
    |> String.to_integer()

  if min_otp <= otp_version do
    :ignore
  else
    raise MinimumOTPError, "minimum required OTP version is 27, got: #{otp_version}"
  end
