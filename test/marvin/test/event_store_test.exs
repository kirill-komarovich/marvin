defmodule Marvin.Test.EventStoreTest do
  use ExUnit.Case, async: true

  alias Marvin.Test.EventStore

  test "store_action/2 stores action under given pid" do
    owner = self()
    EventStore.store_action(owner, :some_action)

    actions = Agent.get(EventStore, &Map.get(&1, owner))

    assert actions == [:some_action]

    EventStore.clear_actions(owner)
  end

  test "pop_action/1 removes and returns first action by given pid" do
    owner = self()

    EventStore.store_action(owner, :some_action)

    assert :some_action == EventStore.pop_action(owner)

    EventStore.clear_actions(owner)
  end

  test "pop_action/1 when no actions stored under given pid returns :no_action" do
    owner = self()

    assert :no_action == EventStore.pop_action(owner)

    EventStore.clear_actions(owner)
  end

  test "clear_actions/1 removes all actions by given pid" do
    owner = self()
    EventStore.store_action(owner, :some_action)
    EventStore.clear_actions(owner)
    actions = Agent.get(EventStore, &Map.get(&1, owner))

    assert is_nil(actions)
  end
end
