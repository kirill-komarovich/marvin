defmodule Marvin.TestTest do
  use ExUnit.Case, async: true

  alias Marvin.Test

  require Test

  defmodule Endpoint do
    def init(opts), do: opts

    def call(event, _opts), do: Marvin.Event.put_assigns(event, :endpoint, true)
  end

  test "event/0 returns test event" do
    assert %Marvin.Event{} = event = Test.event()

    assert event.adapter == Marvin.Test.Adapter
    assert event.owner == self()
    assert event.platform == :test
    assert event.text == ""
    assert event.assigns[:from] == nil
  end

  test "from/1 returns test from" do
    assert %Marvin.Event.From{id: "id"} = Test.from(id: "id")
  end

  @endpoint Endpoint

  test "handle/2 injects test dispatch logic" do
    event = Test.handle(%Marvin.Event{}, "message")

    assert event.text == "message"
    assert event.assigns[:endpoint]
  end

  test "handle/2 injects test dispatch logic with given from" do
    event = Test.handle(%Marvin.Event{}, "message", %{})

    assert event.text == "message"
    assert event.assigns[:endpoint]
    assert event.assigns[:from] == %{}
  end

  @endpoint nil

  test "handle/2 without @endpoint raises error" do
    assert_raise RuntimeError, "no @endpoint set in test case", fn ->
      Test.handle(%Marvin.Event{}, "message")
    end
  end

  test "sent_message/1 returns sent message" do
    Marvin.Test.Notifier.notify(self(), {:send_message, "message", []})

    assert Test.sent_message() == "message"
  end

  test "sent_message/1 without sent message raises error" do
    owner = self()

    assert_raise RuntimeError, "expected send_message action, got: :unknown_action", fn ->
      Marvin.Test.Notifier.notify(owner, :unknown_action)

      Test.sent_message()
    end
  end

  test "sent_message/2 passes sent message and opts in given callback" do
    Marvin.Test.Notifier.notify(self(), {:send_message, "message", [reply: true]})

    Test.sent_message(fn message, opts ->
      assert message == "message"
      assert opts == [reply: true]
    end)
  end

  test "edited_message/1 returns edited message" do
    Marvin.Test.Notifier.notify(self(), {:edit_message, "message", []})

    assert Test.edited_message() == "message"
  end

  test "edited_message/1 without edited message raises error" do
    owner = self()

    assert_raise RuntimeError, "expected edit_message action, got: :unknown_action", fn ->
      Marvin.Test.Notifier.notify(owner, :unknown_action)

      Test.edited_message()
    end
  end

  test "edited_message/2 passes edited message and opts in given callback" do
    Marvin.Test.Notifier.notify(self(), {:edit_message, "message", [reply: true]})

    Test.edited_message(fn message, opts ->
      assert message == "message"
      assert opts == [reply: true]
    end)
  end

  test "answered_callback/1 returns answered message" do
    Marvin.Test.Notifier.notify(self(), {:answer_callback, "message", []})

    assert Test.answered_callback() == "message"
  end

  test "answered_callback/1 without answered message raises error" do
    owner = self()

    assert_raise RuntimeError, "expected answer_callback action, got: :unknown_action", fn ->
      Marvin.Test.Notifier.notify(owner, :unknown_action)

      Test.answered_callback()
    end
  end

  test "answered_callback/2 passes answered message and opts in given callback" do
    Marvin.Test.Notifier.notify(self(), {:answer_callback, "message", [reply: true]})

    Test.answered_callback(fn message, opts ->
      assert message == "message"
      assert opts == [reply: true]
    end)
  end
end
