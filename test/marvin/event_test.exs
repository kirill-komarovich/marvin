defmodule Marvin.EventTest do
  use ExUnit.Case, async: true

  alias Marvin.Event

  defmodule TestAdapter do
    def send_message(event, text, opts), do: [event, text, opts]
  end

  test "send_message/2 calls send_message adapter function with given text" do
    event = %Event{__adapter__: TestAdapter}
    text = "some reply"

    assert [event, text, []] = Event.send_message(event, text)
  end

  test "send_message/3 calls send_message adapter function with given text and opts" do
    event = %Event{__adapter__: TestAdapter}
    text = "some reply"
    opts = [reply: true]

    assert [event, text, opts] = Event.send_message(event, text, opts)
  end

  test "register_before_send/2 returns event with added before send callback" do
    event = %Event{}
    callback = fn _ -> nil end

    assert %Event{before_send: []} = event
    assert %Event{before_send: [callback]} = Event.register_before_send(event, callback)
  end

  test "update_params/2 returns event when new params empty" do
    %Event{params: params} = Event.update_params(%Event{}, %{})

    assert params == %{}
  end

  test "update_params/2 returns event with merger existed and new params" do
    event = %Event{params: %{"name" => "some name"}}
    %Event{params: params} = Event.update_params(event, %{"param" => "some param"})

    assert params == %{"param" => "some param", "name" => "some name"}
  end
end
