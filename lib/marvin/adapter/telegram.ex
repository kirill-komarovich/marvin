defmodule Marvin.Adapter.Telegram do
  @moduledoc """
  Adapter for Nadia Telegram API wrapper
  """

  use Marvin.Adapter

  @command_entity_type "bot_command"
  @platform :telegram

  @impl true
  def get_updates(opts) when is_map(opts) do
    offset = Map.get(opts, :offset)

    run_command(:get_updates, [[offset: offset]])
  end

  @impl true
  def send_message(%Marvin.Event{private: private}, text, opts) do
    options = []

    options =
      if Keyword.get(opts, :reply) do
        Keyword.put(options, :reply_to_message_id, private[:message_id])
      else
        options
      end

    run_command(:send_message, [private[:chat_id], text, options])
  end

  @impl true
  def event(%Nadia.Model.Update{} = update) do
    {message, edited?} = extract_message(update)

    %Marvin.Event{
      adapter: __MODULE__,
      platform: @platform,
      text: event_text(message),
      raw_event: update
    }
    |> Marvin.Event.put_private(:edited?, edited?)
    |> Marvin.Event.put_private(:command?, command?(message))
    |> Marvin.Event.put_private(:event_id, event_id(update))
    |> Marvin.Event.put_private(:message_id, message_id(message))
    |> Marvin.Event.put_private(:chat_id, chat_id(message))
  end

  defp extract_message(%Nadia.Model.Update{message: message, edited_message: nil}),
    do: {message, false}

  defp extract_message(%Nadia.Model.Update{message: nil, edited_message: message}),
    do: {message, true}

  defp command?(%{entities: nil}), do: false

  defp command?(%{entities: entities}) when is_list(entities) do
    Enum.any?(entities, fn %{type: type} -> type == @command_entity_type end)
  end

  defp command?(%{}), do: false

  defp event_text(%Nadia.Model.Message{text: text, sticker: sticker}), do: text || sticker.emoji
  defp event_text(%{text: text}), do: text

  defp event_id(%Nadia.Model.Update{update_id: update_id}), do: update_id

  defp message_id(%{message_id: message_id}), do: message_id

  defp chat_id(%{chat: %{id: chat_id}}), do: chat_id

  defp run_command(command, args) do
    Application.ensure_all_started(:nadia)

    module = Application.get_env(:marvin, :telegram_adapter, Nadia)

    # TODO: convert errors to internal Error struct
    apply(module, command, args)
  end
end
