defmodule Marvin.Telegram.Test do
  alias Marvin.Test.Notifier

  @platform :telegram

  def get_updates(opts) do
    Notifier.notify_callers({@platform, :get_updates, opts})

    [%ExGram.Model.Update{}]
  end

  def send_message(chat_id, text, opts) do
    Notifier.notify_callers({@platform, :send_message, chat_id, text, opts})
  end

  def edit_message_text(chat_id, message_id, inline_message_id, text, opts) do
    Notifier.notify_callers(
      {@platform, :edit_message_text, chat_id, message_id, inline_message_id, text, opts}
    )
  end

  def answer_callback_query(callback_id, opts) do
    Notifier.notify_callers({@platform, :answer_callback_query, callback_id, opts})
  end
end
