defmodule Marvin.Adapter.TestTest do
  use ExUnit.Case, async: true

  alias Marvin.Event
  alias Marvin.Adapter.Test

  test "name/0 returns adapter name" do
    assert "Test" = Test.name()
  end

  test "event/1 returns test event" do
    event = Test.event(%Event{})

    assert event.adapter == Test
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == ""
    assert event.assigns[:from] == nil
  end

  test "event/2 with message returns test event" do
    event = Test.event(%Event{}, "message")

    assert event.adapter == Test
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == "message"
    assert event.assigns[:from] == nil
  end

  test "event/3 with message and sender returns test event" do
    event = Test.event(%Event{}, "message", %{})

    assert event.adapter == Test
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == "message"
    assert event.assigns[:from] == %{}
  end

  test "from/1 when attrs is map returns test sender" do
    attrs = %{id: "id", username: "username"}

    assert %Marvin.Event.From{id: "id", username: "username", raw: ^attrs} = Test.from(attrs)
  end

  test "from/1 when attrs is list returns test sender" do
    assert %Marvin.Event.From{
             id: "id",
             username: "username",
             raw: %{id: "id", username: "username"}
           } = Test.from(id: "id", username: "username")
  end

  setup do
    owner = self()

    on_exit(fn ->
      Marvin.Test.EventStore.clear_actions(owner)
    end)

    [owner: owner]
  end

  test "send_message/3 stores send_message action in EventStore", %{owner: owner} do
    text = "message"
    opts = []

    Test.send_message(%Event{owner: owner}, text, opts)

    assert {:send_message, ^text, ^opts} = Marvin.Test.EventStore.pop_action(owner)
    assert :no_action == Marvin.Test.EventStore.pop_action(owner)
  end

  test "edit_message/3 stores edit_message action in EventStore", %{owner: owner} do
    text = "message"
    opts = []

    Test.edit_message(%Event{owner: owner}, text, opts)

    assert {:edit_message, ^text, ^opts} = Marvin.Test.EventStore.pop_action(owner)
    assert :no_action == Marvin.Test.EventStore.pop_action(owner)
  end

  test "answer_callback/3 stores answer_callback action in EventStore", %{owner: owner} do
    text = "message"
    opts = []

    Test.answer_callback(%Event{owner: owner}, text, opts)

    assert {:answer_callback, ^text, ^opts} = Marvin.Test.EventStore.pop_action(owner)
    assert :no_action == Marvin.Test.EventStore.pop_action(owner)
  end
end
