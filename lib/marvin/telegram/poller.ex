defmodule Marvin.Telegram.Poller do
  use Marvin.Poller, adapter: Marvin.Telegram

  def update_state(state, []), do: state

  def update_state(state, updates) do
    last_update = List.last(updates)

    Map.put(state, :offset, last_update.update_id + 1)
  end
end
