defmodule Marvin.EndpointTest do
  use ExUnit.Case, async: true

  defmodule Endpoint do
    use Marvin.Endpoint, otp_app: :marvin

    assert @otp_app == :marvin
  end
end
