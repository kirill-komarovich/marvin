defmodule Marvin.Adapter.Test do
  use Marvin.Adapter

  alias Marvin.Test.EventStore

  @platform :test

  def event(event, message \\ "", from \\ nil) do
    owner = self()

    %Marvin.Event{
      event
      | adapter: __MODULE__,
        owner: owner,
        platform: @platform,
        text: message
    }
    |> Marvin.Event.put_assigns(:from, from)
  end

  def from(attrs) when is_list(attrs) do
    attrs
    |> Enum.into(%{})
    |> from()
  end

  def from(attrs) when is_map(attrs) do
    %Marvin.Event.From{
      id: attrs[:id],
      first_name: attrs[:first_name],
      last_name: attrs[:last_name],
      username: attrs[:username],
      raw: attrs
    }
  end

  def send_message(%Marvin.Event{owner: owner}, text, opts) do
    EventStore.store_action(owner, {:send_message, text, opts})
  end

  def edit_message(%Marvin.Event{owner: owner}, text, opts) do
    EventStore.store_action(owner, {:edit_message, text, opts})
  end

  def answer_callback(%Marvin.Event{owner: owner}, text, opts) do
    EventStore.store_action(owner, {:answer_callback, text, opts})
  end
end
