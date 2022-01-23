defmodule Marvin.EventTest do
  use ExUnit.Case, async: true

  alias Marvin.Event

  defmodule TestAdapter do
    def send_message(event, text, opts) do
      send(self(), [event, text, opts])
    end

    def edit_message(event, text, opts) do
      send(self(), [event, text, opts])
    end

    def answer_callback(event, text, opts) do
      send(self(), [event, text, opts])
    end

    def from(%{from: from}) do
      raw = from
      from = from

      %Marvin.Event.From{
        id: from[:id],
        username: from[:username],
        raw: raw
      }
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

  test "merge_assigns/2 updates assigns attributes" do
    event = %Event{assigns: %{}}

    assert %Event{assigns: %{key: "value"}} = Event.merge_assigns(event, key: "value")
  end

  test "put_private/3 updates private attributes" do
    event = %Event{private: %{key: "value"}}

    assert %Event{private: %{key: "new value"}} = Event.put_private(event, :key, "new value")
  end

  test "merge_private/2 updates assigns attributes" do
    event = %Event{private: %{}}

    assert %Event{private: %{key: "value"}} = Event.merge_private(event, key: "value")
  end

  test "halt/1 updates halt attribute" do
    event = %Event{}

    assert %Event{halted: true} = Event.halt(event)
  end

  test "edit_message/2 calls edit_message adapter function with given text" do
    event = %Event{adapter: TestAdapter}
    text = "some reply"
    Event.edit_message(event, text)

    assert_receive [^event, ^text, []]
  end

  test "edit_message/3 calls edit_message adapter function with given text and opts" do
    event = %Event{adapter: TestAdapter}
    text = "some reply"
    opts = [markup: "some_markup"]
    Event.edit_message(event, text, opts)

    assert_receive [^event, ^text, ^opts]
  end

  test "put_from/1 sets event sender to from assigns key" do
    from = %{id: 1, username: "name"}
    event = %Event{adapter: TestAdapter, raw_event: %{from: from}}

    assert %Marvin.Event{
             assigns: %{
               from: %Event.From{
                 id: id,
                 username: username,
                 raw: ^from
               }
             }
           } = Event.put_from(event)

    assert id == from[:id]
    assert username == from[:username]
  end

  test "answer_callback/2 calls answer_callback adapter function with given text" do
    event = %Event{adapter: TestAdapter}
    text = "some reply"

    Event.answer_callback(event, text)

    assert_receive [^event, ^text, []]
  end

  test "answer_callback/3 calls answer_callback adapter function with given text and opts" do
    event = %Event{adapter: TestAdapter}
    text = "some reply"
    opts = [alert: true]

    Event.answer_callback(event, text, opts)

    assert_receive [^event, ^text, ^opts]
  end
end
