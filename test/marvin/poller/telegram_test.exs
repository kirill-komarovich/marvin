defmodule Marvin.Poller.TelegramTest do
  use ExUnit.Case, async: true

  alias Marvin.Poller.Telegram

  test "update_state/2 updates state offset" do
    updates = [%{update_id: 1}]

    assert %{offset: 2} = Telegram.update_state(%{offset: 0}, updates)
  end

  test "update_state/2 when updates is empty list does not modify state" do
    state = %{offset: 0}

    assert ^state = Telegram.update_state(state, [])
  end
end
