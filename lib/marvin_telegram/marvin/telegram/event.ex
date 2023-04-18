defmodule Marvin.Telegram.Event do
  @moduledoc """
  Event builder for Telegram adapter
  """

  @command_entity_type "bot_command"

  def event(%ExGram.Model.Update{callback_query: callback_query} = update) do
    {message, edited?} = extract_message(update)

    %Marvin.Event{
      adapter: Marvin.Telegram,
      platform: Marvin.Telegram.platform(),
      text: event_text(callback_query || message),
      owner: self(),
      raw_event: update
    }
    |> Marvin.Event.merge_private(
      edited?: edited?,
      command?: command?(message),
      callback?: callback?(callback_query),
      callback_id: callback_id(callback_query),
      callback_message_text: callback_message_text(callback_query),
      event_id: event_id(update),
      message_id: message_id(message),
      chat_id: chat_id(message)
    )
    |> Marvin.Event.put_assigns(:from, from(update))
  end

  defp extract_message(%ExGram.Model.Update{
         callback_query: %ExGram.Model.CallbackQuery{message: message}
       }),
       do: {message, false}

  defp extract_message(%ExGram.Model.Update{message: message, edited_message: nil}),
    do: {message, false}

  defp extract_message(%ExGram.Model.Update{message: nil, edited_message: message}),
    do: {message, true}

  defp command?(%{entities: nil}), do: false

  defp command?(%{entities: entities}) when is_list(entities) do
    Enum.any?(entities, fn %{type: type} -> type == @command_entity_type end)
  end

  defp command?(%{}), do: false

  defp callback?(%ExGram.Model.CallbackQuery{}), do: true
  defp callback?(_), do: false

  defp callback_id(%ExGram.Model.CallbackQuery{id: id}), do: id
  defp callback_id(_), do: nil

  defp event_text(%ExGram.Model.CallbackQuery{data: data}), do: data
  defp event_text(%ExGram.Model.Message{text: text, sticker: sticker}), do: text || sticker.emoji
  defp event_text(%{text: text}), do: text

  defp callback_message_text(%ExGram.Model.CallbackQuery{message: message}),
    do: event_text(message)

  defp callback_message_text(_), do: nil

  defp event_id(%ExGram.Model.Update{update_id: update_id}), do: update_id

  defp message_id(%{message_id: message_id}), do: message_id

  defp chat_id(%{chat: %{id: chat_id}}), do: chat_id

  def from(%ExGram.Model.Update{message: %{from: from}}) do
    convert_from(from)
  end

  def from(%ExGram.Model.Update{edited_message: %{from: from}}) do
    convert_from(from)
  end

  def from(%ExGram.Model.Update{callback_query: %ExGram.Model.CallbackQuery{from: from}}) do
    convert_from(from)
  end

  defp convert_from(from) when is_map(from) do
    raw = from
    from = if is_nil(Map.get(from, :__struct__)), do: from, else: Map.from_struct(from)

    %Marvin.Event.From{
      id: from[:id],
      first_name: from[:first_name],
      last_name: from[:last_name],
      username: from[:username],
      raw: raw
    }
  end

end
