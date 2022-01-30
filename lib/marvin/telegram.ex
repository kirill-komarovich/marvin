defmodule Marvin.Telegram do
  @moduledoc """
  Adapter for Nadia Telegram API wrapper
  """

  use Marvin.Adapter

  @command_entity_type "bot_command"
  @platform :telegram

  def get_updates(opts) do
    offset = Keyword.get(opts, :offset)

    run_command(:get_updates, [[offset: offset]])
  end

  @impl true
  def send_message(%Marvin.Event{private: private}, text, opts) do
    send_message(private[:chat_id], text, convert_opts(private, opts))
  end

  def send_message(chat_id, text, opts) do
    adapter_opts = adapter_opts(opts)
    options = send_options(opts)

    run_command(:send_message, [chat_id, text, options ++ adapter_opts])
  end

  defp convert_opts(private, opts) do
    Enum.reduce(opts, [], fn
      {:reply, true}, acc ->
        Keyword.put(acc, :reply, private[:message_id])

      {key, value}, acc ->
        Keyword.put(acc, key, value)
    end)
  end

  defp send_options(opts) do
    Enum.reduce(opts, [], fn
      {:reply, message_id}, acc ->
        Keyword.put(acc, :reply_to_message_id, message_id)

      {:keyboard, keyboard}, acc ->
        Keyword.put(acc, :reply_markup, Marvin.Telegram.Keyboard.to_markup(keyboard))

      _, acc ->
        acc
    end)
  end

  @impl true
  def edit_message(%Marvin.Event{private: private}, text, opts) do
    edit_message(private[:chat_id], private[:message_id], private[:inline_message_id], text, opts)
  end

  def edit_message(chat_id, message_id, inline_message_id, text, opts) do
    adapter_opts = adapter_opts(opts)
    options = edit_options(opts)

    run_command(
      :edit_message_text,
      [
        chat_id,
        message_id,
        inline_message_id,
        text,
        options ++ adapter_opts
      ]
    )
  end

  defp edit_options(opts) do
    Enum.reduce(opts, [], fn
      {:keyboard, keyboard}, acc ->
        Keyword.put(acc, :reply_markup, Marvin.Telegram.Keyboard.to_markup(keyboard))

      _, acc ->
        acc
    end)
  end

  @impl true
  def answer_callback(%Marvin.Event{private: private}, text, opts) do
    alert? = Keyword.get(opts, :alert, false)

    run_command(:answer_callback_query, [private[:callback_id], [text: text, show_alert: alert?]])
  end

  defp adapter_opts(opts) do
    opts
    |> Keyword.get(:adapter_opts, [])
    |> Keyword.get(@platform, [])
  end

  def event(%Nadia.Model.Update{callback_query: callback_query} = update) do
    {message, edited?} = extract_message(update)

    %Marvin.Event{
      adapter: __MODULE__,
      platform: @platform,
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

  defp callback?(%Nadia.Model.CallbackQuery{}), do: true
  defp callback?(_), do: false

  defp callback_id(%Nadia.Model.CallbackQuery{id: id}), do: id
  defp callback_id(_), do: nil

  defp event_text(%Nadia.Model.CallbackQuery{data: data}), do: data
  defp event_text(%Nadia.Model.Message{text: text, sticker: sticker}), do: text || sticker.emoji
  defp event_text(%{text: text}), do: text

  defp callback_message_text(%Nadia.Model.CallbackQuery{message: message}),
    do: event_text(message)

  defp callback_message_text(_), do: nil

  defp event_id(%Nadia.Model.Update{update_id: update_id}), do: update_id

  defp message_id(%{message_id: message_id}), do: message_id

  defp chat_id(%{chat: %{id: chat_id}}), do: chat_id

  def from(%Nadia.Model.Update{message: %{from: from}}) do
    convert_from(from)
  end

  def from(%Nadia.Model.Update{edited_message: %{from: from}}) do
    convert_from(from)
  end

  def from(%Nadia.Model.Update{callback_query: %Nadia.Model.CallbackQuery{from: from}}) do
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

  defp run_command(command, args) do
    Application.ensure_all_started(:nadia)

    module = Application.get_env(:marvin, :telegram_adapter, Nadia)

    # TODO: convert errors to internal Error struct?
    case apply(module, command, args) do
      {:error, error} ->
        raise "Failed to process `#{command}` with #{inspect(args)} arguments.\n\nReason: #{inspect(error)}"

      value ->
        value
    end
  end
end
