defmodule Marvin.Telegram do
  @moduledoc """
  Adapter for ExGram Telegram API wrapper
  """

  use Marvin.Adapter

  def get_updates(opts) do
    offset = Keyword.get(opts, :offset, 0)

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

  def event(update) do
    Marvin.Telegram.Event.event(update)
  end

  def from(update) do
    Marvin.Telegram.Event.from(update)
  end

  defp run_command(command, args) do
    # TODO: convert errors to internal Error struct?
    case apply(get_client(), command, args) do
      {:error, error} ->
        raise "Failed to process `#{command}` with #{inspect(args)} arguments.\n\nReason: #{inspect(error)}"

      value ->
        value
    end
  end

  defp get_client do
    module = Application.get_env(:marvin, :telegram_client, ExGram)
    otp_app = Application.get_application(module)
    Application.ensure_all_started(otp_app)

    module
  end
end
