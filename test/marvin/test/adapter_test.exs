defmodule Marvin.Test.AdapterTest do
  use ExUnit.Case, async: true

  alias Marvin.Event
  alias Marvin.Test.Adapter

  test "name/0 returns adapter name" do
    assert "Test" = Adapter.name()
  end

  test "event/1 returns test event" do
    event = Adapter.event(%Event{})

    assert event.adapter == Adapter
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == ""
    assert event.assigns[:from] == nil
  end

  test "event/2 with message returns test event" do
    event = Adapter.event(%Event{}, "message")

    assert event.adapter == Adapter
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == "message"
    assert event.assigns[:from] == nil
  end

  test "event/3 with message and sender returns test event" do
    event = Adapter.event(%Event{}, "message", %{})

    assert event.adapter == Adapter
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == "message"
    assert event.assigns[:from] == %{}
  end

  test "from/1 when attrs is map returns test sender" do
    attrs = %{id: "id", username: "username"}

    assert %Marvin.Event.From{id: "id", username: "username", raw: ^attrs} = Adapter.from(attrs)
  end

  test "from/1 when attrs is list returns test sender" do
    assert %Marvin.Event.From{
             id: "id",
             username: "username",
             raw: %{id: "id", username: "username"}
           } = Adapter.from(id: "id", username: "username")
  end
end
