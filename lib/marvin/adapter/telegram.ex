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
    options = send_options(private, opts)

    run_command(:send_message, [private[:chat_id], text, options])
  end

  defp send_options(private, opts) do
    Enum.reduce(opts, [], fn
      {:reply, true}, acc ->
        Keyword.put(acc, :reply_to_message_id, private[:message_id])

      {:keyboard, keyboard}, acc ->
        Keyword.put(acc, :reply_markup, Marvin.Adapter.Telegram.Keyboard.to_markup(keyboard))

      _, acc ->
        acc
    end)
  end

  @impl true
  def edit_message(%Marvin.Event{private: private}, text, opts) do
    options = edit_options(opts)

    run_command(
      :edit_message_text,
      [private[:chat_id], private[:message_id], private[:inline_message_id], text, options]
    )
  end

  defp edit_options(opts) do
    Enum.reduce(opts, [], fn
      {:keyboard, keyboard}, acc ->
        Keyword.put(acc, :reply_markup, Marvin.Adapter.Telegram.Keyboard.to_markup(keyboard))

      _, acc ->
        acc
    end)
  end

  @impl true
  def event(%Nadia.Model.Update{callback_query: callback_query} = update) do
    {message, edited?} = extract_message(update)

    %Marvin.Event{
      adapter: __MODULE__,
      platform: @platform,
      text: event_text(callback_query || message),
      raw_event: update
    }
    |> Marvin.Event.put_private(:edited?, edited?)
    |> Marvin.Event.put_private(:command?, command?(message))
    |> Marvin.Event.put_private(:event_id, event_id(update))
    |> Marvin.Event.put_private(:message_id, message_id(message))
    |> Marvin.Event.put_private(:chat_id, chat_id(message))
  end

  defp extract_message(%Nadia.Model.Update{
         callback_query: %Nadia.Model.CallbackQuery{message: message}
       }),
       do: {message, false}

  defp extract_message(%Nadia.Model.Update{message: message, edited_message: nil}),
    do: {message, false}

  defp extract_message(%Nadia.Model.Update{message: nil, edited_message: message}),
    do: {message, true}

  defp command?(%{entities: nil}), do: false

  defp command?(%{entities: entities}) when is_list(entities) do
    Enum.any?(entities, fn %{type: type} -> type == @command_entity_type end)
  end

  defp command?(%{}), do: false

  defp event_text(%Nadia.Model.CallbackQuery{data: data}), do: data
  defp event_text(%Nadia.Model.Message{text: text, sticker: sticker}), do: text || sticker.emoji
  defp event_text(%{text: text}), do: text

  defp event_id(%Nadia.Model.Update{update_id: update_id}), do: update_id

  defp message_id(%{message_id: message_id}), do: message_id

  defp chat_id(%{chat: %{id: chat_id}}), do: chat_id

  @impl true
  def from(%Nadia.Model.Update{message: %{from: from}}) do
    convert_from(from)
  end

  def from(%Nadia.Model.Update{callback_query: callback_query}) do
    from(callback_query)
  end

  def from(%Nadia.Model.CallbackQuery{from: from}) do
    convert_from(from)
  end

  defp convert_from(from) do
    raw = from
    from = Map.from_struct(from)

    %Marvin.Event.From{
      id: from[:id],
      first_name: from[:first_name],
      last_name: from[:last_name],
      username: from[:username],
      raw: raw
    }
  end

  defp run_command(command, args) do
    Application.ensure_all_started(:nadia)

    module = Application.get_env(:marvin, :telegram_adapter, Nadia)

    # TODO: convert errors to internal Error struct
    apply(module, command, args)
  end
end
