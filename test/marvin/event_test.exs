defmodule Marvin.EventTest do
  use ExUnit.Case, async: true

  doctest Marvin.Event

  alias Marvin.Event

  defmodule TestAdapter do
    def send_message(event, text, opts) do
      send(self(), [event, text, opts])
    end
  end

  test "send_message/2 calls send_message adapter function with given text" do
    event = %Event{adapter: TestAdapter}
    text = "some reply"
    Event.send_message(event, text)

    assert_receive [^event, ^text, []]
  end

  test "send_message/3 calls send_message adapter function with given text and opts" do
    event = %Event{adapter: TestAdapter}
    text = "some reply"
    opts = [reply: true]

    Event.send_message(event, text, opts)

    assert_receive [^event, ^text, ^opts]
  end

  test "send_messages/2 calls send_message adapter function for each given message" do
    event = %Event{adapter: TestAdapter}

    messages = [
      {"message 1", [reply: true]},
      {"message 2", []},
      "message 3"
    ]

    Event.send_messages(event, messages)

    Enum.each(messages, fn
      {text, opts} ->
        assert_receive [^event, ^text, ^opts]

      text when is_binary(text) ->
        assert_receive [^event, ^text, []]
    end)
  end

  test "register_before_send/2 returns event with added before send callback" do
    event = %Event{}
    callback = fn _ -> nil end

    assert %Event{before_send: []} = event
    assert %Event{before_send: [^callback]} = Event.register_before_send(event, callback)
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

  test "put_assigns/3 updates assigns attributes" do
    event = %Event{assigns: %{key: "value"}}

    assert %Event{assigns: %{key: "new value"}} = Event.put_assigns(event, :key, "new value")
  end

  test "put_private/3 updates private attributes" do
    event = %Event{private: %{key: "value"}}

    assert %Event{private: %{key: "new value"}} = Event.put_private(event, :key, "new value")
  end

  test "halt/1 updates halt attribute" do
    event = %Event{}

    assert %Event{halted: true} = Event.halt(event)
  end

  test "halt/1 does not update halt attribute when event already halted" do
    event = %Event{halted: true}

    assert ^event = Event.halt(event)
  end
end
