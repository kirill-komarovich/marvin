defmodule Marvin.EndpointTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  alias Marvin.Event

  defmodule TestMatcher do
    def call(event) do
      event = Enum.reduce(event.before_send, event, & &1.(&2))

      {:ok, event.text}
    end
  end

  defmodule Endpoint do
    use Marvin.Endpoint, otp_app: :marvin

    assert @otp_app == :marvin

    poller TestPoller
    poller TestPollerWithOpts, some: "opt"

    matcher TestMatcher
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

  test "__matcher__/0 returns matcher for current endpoint" do
    assert TestMatcher == Endpoint.__matcher__()
  end

  @tag capture_log: true
  test "call/1 calls matcher call/1 with given event" do
    event = %Event{text: "hello"}

    assert {:ok, "hello"} = Endpoint.call(event)
  end

  test "call/1 logs endpoint start and stop" do
    platform = :telegram
    event = %Event{platform: platform, text: "hello"}

    fun = fn -> Endpoint.call(event) end

    assert capture_log(fun) =~ ~r"\[info\]  Get #{platform} update"u
    assert capture_log(fun) =~ ~r"\[info\]  Finished in [0-9]+[m|µ]s"u
  end
end
