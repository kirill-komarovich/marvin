defmodule Marvin.EndpointTest do
  use ExUnit.Case, async: true

  doctest Marvin.Endpoint

  defmodule Endpoint do
    use Marvin.Endpoint, otp_app: :test_app

    assert @otp_app == :test_app

    poller TestPoller
    poller TestPollerWithOpts, some: "opt"
  end

  test "child_spec/1 returns supervisor spec" do
    opts = []

    spec = %{
      id: Endpoint,
      start: {Endpoint, :start_link, [opts]},
      type: :supervisor
    }

    assert ^spec = Endpoint.child_spec(opts)
  end

  test "__pollers__/0 returns registered pollers" do
    pollers = [
      {TestPollerWithOpts, [some: "opt"]},
      {TestPoller, []}
    ]

    assert pollers == Endpoint.__pollers__()
  end
end
