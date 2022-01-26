defmodule Marvin.Test.EventStore do
  def start_link do
    Agent.start_link(fn -> Map.new() end, name: __MODULE__)
  end

  def store_action(owner, action) do
    Agent.update(__MODULE__, fn state ->
      actions = Map.get(state, owner, [])

      Map.put(state, owner, actions ++ [action])
    end)
  end

  def pop_action(owner) do
    Agent.get_and_update(__MODULE__, fn state ->
      case Map.get(state, owner, []) do
        [action | actions] ->
          {action, Map.put(state, owner, actions)}

        [] ->
          {:no_action, state}
      end
    end)
  end

  def clear_actions(owner) do
    Agent.update(__MODULE__, fn state ->
      Map.delete(state, owner)
    end)
  end
end
