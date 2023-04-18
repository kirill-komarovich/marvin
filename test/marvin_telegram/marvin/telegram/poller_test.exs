defmodule Marvin.Telegram.PollerTest do
  use ExUnit.Case, async: true

  alias Marvin.Telegram.Poller

  test "update_state/2 updates state offset" do
    updates = [%{update_id: 1}]

    assert %{offset: 2} = Poller.update_state(%{offset: 0}, updates)
  end

  test "update_state/2 when updates is empty list does not modify state" do
    state = %{offset: 0}

    assert ^state = Poller.update_state(state, [])
  end
end
