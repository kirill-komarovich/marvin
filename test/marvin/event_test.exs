defmodule Marvin.EventTest do
  use ExUnit.Case, async: true

  import Marvin.Test

  alias Marvin.Event

  setup do
    self = self()

    on_exit(fn ->
      Marvin.Test.EventStore.clear_actions(self)
    end)
  end

  test "send_message/2 calls send_message adapter function with given text" do
    event = Event.send_message(event(), "some reply")

    assert sent_message(event) == "some reply"
  end

  test "send_message/3 calls send_message adapter function with given text and opts" do
    event = Event.send_message(event(), "some reply", reply: true)

    sent_message(event, fn message, opts ->
      assert message == "some reply"
      assert opts == [reply: true]
    end)
  end

  test "send_messages/2 calls send_message adapter function for each given message" do
    event =
      Event.send_messages(
        event(),
        [
          {"message 1", [reply: true]},
          {"message 2", []},
          "message 3"
        ]
      )

    sent_message(event, fn message, opts ->
      assert message == "message 1"
      assert opts == [reply: true]
    end)

    sent_message(event, fn message, opts ->
      assert message == "message 2"
      assert opts == []
    end)

    assert sent_message(event) == "message 3"
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
    event = Event.edit_message(event(), "some reply")

    assert edited_message(event) == "some reply"
  end

  test "edit_message/3 calls edit_message adapter function with given text and opts" do
    event = Event.edit_message(event(), "some reply", markup: "some_markup")

    edited_message(event, fn message, opts ->
      assert message == "some reply"
      assert opts == [markup: "some_markup"]
    end)
  end

  test "put_from/1 sets event sender to from assigns key" do
    from = %{id: 1, username: "name"}
    event = %{event() | raw_event: from}

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
    event = Event.answer_callback(event(), "some reply")

    assert answered_callback(event) == "some reply"
  end

  test "answer_callback/3 calls answer_callback adapter function with given text and opts" do
    event = Event.answer_callback(event(), "some reply", alert: true)

    answered_callback(event, fn message, opts ->
      assert message == "some reply"
      assert opts == [alert: true]
    end)
  end
end
