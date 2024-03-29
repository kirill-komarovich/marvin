defmodule Marvin.MatcherTest do
  use ExUnit.Case, async: true

  alias Marvin.Event

  defmodule RegexHandler do
    def call(event, _opts) do
      {__MODULE__, event}
    end
  end

  defmodule StringHandler do
    def call(event, _opts) do
      {__MODULE__, event}
    end
  end

  defmodule Matcher do
    use Marvin.Matcher

    handle ~r/test_regex/, RegexHandler
    handle "test_string", StringHandler
  end

  test "__handlers__/0 returns all registered handlers with patterns" do
    expected = [
      {RegexHandler, {~r/test_regex/, []}},
      {StringHandler, {"test_string", []}}
    ]

    assert Matcher.__handlers__() == expected
  end

  @tag capture_log: true
  test "call/2 when triggers regex pattern" do
    event = %Event{text: "test_regex"}

    assert {RegexHandler, new_event} = Matcher.call(event, [])
    assert new_event == %{event | private: %{marvin_matcher: Matcher}}
  end

  @tag capture_log: true
  test "call/2 when triggers string pattern" do
    event = %Event{text: "test_string"}

    assert {StringHandler, new_event} = Matcher.call(event, [])
    assert new_event == %{event | private: %{marvin_matcher: Matcher}}
  end

  test "call/2 when no handler found" do
    event = %Event{text: "unknown", platform: :unknown}
    message = "no handler found for #{event.platform} message: #{event.text}"

    assert_raise Marvin.Matcher.NoHandlerError, message, fn ->
      Matcher.call(event, [])
    end
  end

  @tag capture_log: true
  test "telemetry", %{test: test} do
    self = self()
    event = %Event{text: "test_string"}

    :ok =
      :telemetry.attach_many(
        "#{test}",
        [
          [:marvin, :matcher, :start],
          [:marvin, :matcher, :stop],
          [:marvin, :matcher_dispatch, :start]
        ],
        fn name, measurements, metadata, _ ->
          send(self, {:telemetry_event, name, measurements, metadata})
        end,
        nil
      )

    Matcher.call(event, [])

    assert_receive {:telemetry_event, [:marvin, :matcher, :start], %{system_time: _},
                    %{event: ^event}}

    assert_receive {:telemetry_event, [:marvin, :matcher, :stop], %{duration: _},
                    %{event: ^event}}

    event = %{event | private: %{marvin_matcher: Matcher}}

    assert_receive {:telemetry_event, [:marvin, :matcher_dispatch, :start], %{system_time: _},
                    %{event: ^event}}

    :telemetry.detach("#{test}")
  end
end
