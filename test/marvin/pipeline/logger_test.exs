defmodule Marvin.Pipeline.LoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  alias Marvin.Pipeline
  alias Marvin.Event

  @platform :some_platform

  test "call/2 logs endpoint start and stop" do
    event = %Event{platform: @platform, text: "hello"}

    fun = fn ->
      %{before_send: before_send} = event = Pipeline.Logger.call(event, [])

      Enum.reduce(before_send, event, & &1.(&2))
    end

    assert capture_log(fun) =~ ~r"\[info\]  Get #{@platform} update"u
    assert capture_log(fun) =~ ~r"\[info\]  Finished in [0-9]+[m|µ]s"u
  end
end
