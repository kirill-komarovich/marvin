defmodule Marvin.Adapter.TelegramTest do
  use ExUnit.Case, async: true

  alias Marvin.Adapter.Telegram

  defmodule FakeNadia do
    def get_updates(opts) do
      send(self(), {:get_updates, opts})

      [%Nadia.Model.Update{}]
    end

    def send_message(chat_id, text, opts) do
      send(self(), {:send_message, chat_id, text, opts})
    end

    def edit_message_text(chat_id, message_id, inline_message_id, text, opts) do
      send(self(), {:edit_message_text, chat_id, message_id, inline_message_id, text, opts})
    end

    def answer_callback_query(callback_id, opts) do
      send(self(), {:answer_callback_query, callback_id, opts})
    end
  end

  setup do
    Application.put_env(:marvin, :telegram_adapter, FakeNadia)

    on_exit(fn ->
      Application.put_env(:marvin, :telegram_adapter, nil)
    end)
  end

  test "name/0 returns adapter name" do
    assert "Telegram" = Telegram.name()
  end

  test "get_updates/1 returns list of updates" do
    offset = 1

    assert [%Nadia.Model.Update{}] = Telegram.get_updates(offset: offset)

    assert_receive {:get_updates, [offset: ^offset]}
  end

  test "send_message/3 sends message by chat_id inside event" do
    chat_id = :chat_id
    text = "message"

    Telegram.send_message(%Marvin.Event{private: %{chat_id: chat_id}}, text, [])

    assert_receive {:send_message, ^chat_id, ^text, []}
  end

  test "send_message/3 sends message by chat_id" do
    chat_id = :chat_id
    text = "message"

    Telegram.send_message(chat_id, text, [])

    assert_receive {:send_message, ^chat_id, ^text, []}
  end

  test "send_message/3 with reply option sends message by chat_id and message_id inside event" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"

    Telegram.send_message(
      %Marvin.Event{private: %{message_id: message_id, chat_id: chat_id}},
      text,
      reply: true
    )

    assert_receive {:send_message, ^chat_id, ^text, [reply_to_message_id: ^message_id]}
  end

  test "send_message/3 with reply option sends message by chat_id and message_id" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"

    Telegram.send_message(
      chat_id,
      text,
      reply: message_id
    )

    assert_receive {:send_message, ^chat_id, ^text, [reply_to_message_id: ^message_id]}
  end

  test "send_message/3 with keyboard option sends message with reply markup" do
    chat_id = :chat_id
    text = "message"
    keyboard = %Marvin.Event.Keyboard{type: :inline}
    markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: [[]]}

    Telegram.send_message(%Marvin.Event{private: %{chat_id: chat_id}}, text, keyboard: keyboard)

    assert_receive {:send_message, ^chat_id, ^text, [reply_markup: ^markup]}
  end

  test "send_message/3 with unknown option sends message by chat_id" do
    chat_id = :chat_id
    text = "message"

    Telegram.send_message(%Marvin.Event{private: %{chat_id: chat_id}}, text, unknown: :value)

    assert_receive {:send_message, ^chat_id, ^text, []}
  end

  test "edit_message/3 edits messages by chat_id and message_id inside event" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"

    Telegram.edit_message(
      %Marvin.Event{private: %{chat_id: chat_id, message_id: message_id}},
      text,
      []
    )

    assert_receive {:edit_message_text, ^chat_id, ^message_id, nil, ^text, []}
  end

  test "edit_message/3 edits messages by chat_id and message_id" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"

    Telegram.edit_message(chat_id, message_id, nil, text, [])

    assert_receive {:edit_message_text, ^chat_id, ^message_id, nil, ^text, []}
  end

  test "edit_message/3 with keyboard option edits messages by chat_id and message_id with reply markup" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"
    keyboard = %Marvin.Event.Keyboard{type: :inline}
    markup = %Nadia.Model.InlineKeyboardMarkup{inline_keyboard: [[]]}

    Telegram.edit_message(
      %Marvin.Event{private: %{chat_id: chat_id, message_id: message_id}},
      text,
      keyboard: keyboard
    )

    assert_receive {:edit_message_text, ^chat_id, ^message_id, nil, ^text,
                    [reply_markup: ^markup]}
  end

  test "edit_message/3 with unknown option edits messages by chat_id and message_id" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"

    Telegram.edit_message(
      %Marvin.Event{private: %{chat_id: chat_id, message_id: message_id}},
      text,
      unknown: :value
    )

    assert_receive {:edit_message_text, ^chat_id, ^message_id, nil, ^text, []}
  end

  test "answer_callback/3 sends callback answer by callback_id" do
    callback_id = :callback_id
    text = "alert"

    Telegram.answer_callback(
      %Marvin.Event{private: %{callback_id: callback_id}},
      text,
      []
    )

    assert_receive {:answer_callback_query, ^callback_id, [text: ^text, show_alert: false]}
  end

  test "answer_callback/3 with alert option sends callback answer by callback_id as alert" do
    callback_id = :callback_id
    text = "alert"

    Telegram.answer_callback(
      %Marvin.Event{private: %{callback_id: callback_id}},
      text,
      alert: true
    )

    assert_receive {:answer_callback_query, ^callback_id, [text: ^text, show_alert: true]}
  end

  test "event/1 converts Nadia.Update to Marvin.Event" do
    update = %Nadia.Model.Update{
      update_id: :update_id,
      message: %Nadia.Model.Message{
        text: "text",
        entities: nil,
        message_id: :message_id,
        chat: %{
          id: :chat_id
        }
      }
    }

    assert %Marvin.Event{
             adapter: Telegram,
             platform: :telegram,
             text: "text",
             private: %{
               edited?: false,
               command?: false,
               event_id: :update_id,
               chat_id: :chat_id,
               message_id: :message_id
             },
             raw_event: ^update
           } = Telegram.event(update)
  end

  test "event/1 with sticker converts Nadia.Update to Marvin.Event" do
    update = %Nadia.Model.Update{
      update_id: :update_id,
      message: %Nadia.Model.Message{
        text: nil,
        sticker: %Nadia.Model.Sticker{emoji: "👍"},
        entities: nil,
        message_id: :message_id,
        chat: %{
          id: :chat_id
        }
      }
    }

    assert %Marvin.Event{
             adapter: Telegram,
             platform: :telegram,
             text: "👍",
             private: %{
               edited?: false,
               command?: false,
               event_id: :update_id,
               chat_id: :chat_id,
               message_id: :message_id
             },
             raw_event: ^update
           } = Telegram.event(update)
  end

  test "event/1 with edited message converts Nadia.Update to Marvin.Event" do
    update = %Nadia.Model.Update{
      update_id: :update_id,
      edited_message: %{
        text: "text",
        entities: nil,
        message_id: :message_id,
        chat: %{
          id: :chat_id
        }
      }
    }

    assert %Marvin.Event{
             adapter: Telegram,
             platform: :telegram,
             text: "text",
             private: %{
               edited?: true,
               command?: false,
               event_id: :update_id,
               chat_id: :chat_id,
               message_id: :message_id
             },
             raw_event: ^update
           } = Telegram.event(update)
  end

  test "event/1 with command converts Nadia.Update to Marvin.Event" do
    update = %Nadia.Model.Update{
      update_id: :update_id,
      message: %Nadia.Model.Message{
        text: "text",
        entities: [%{type: "bot_command"}],
        message_id: :message_id,
        chat: %{
          id: :chat_id
        }
      }
    }

    assert %Marvin.Event{
             adapter: Telegram,
             platform: :telegram,
             text: "text",
             private: %{
               edited?: false,
               command?: true,
               event_id: :update_id,
               chat_id: :chat_id,
               message_id: :message_id
             },
             raw_event: ^update
           } = Telegram.event(update)
  end

  test "event/1 with callback_query Nadia.Update to Marvin.Event" do
    update = %Nadia.Model.Update{
      update_id: :update_id,
      callback_query: %Nadia.Model.CallbackQuery{
        data: "some_data",
        message: %Nadia.Model.Message{
          text: "",
          entities: nil,
          message_id: :message_id,
          chat: %{
            id: :chat_id
          }
        }
      }
    }

    assert %Marvin.Event{
             adapter: Telegram,
             platform: :telegram,
             text: "some_data",
             private: %{
               edited?: false,
               command?: false,
               event_id: :update_id,
               chat_id: :chat_id,
               message_id: :message_id
             },
             raw_event: ^update
           } = Telegram.event(update)
  end

  test "from/1 extracts sender and converts it to marvin structure" do
    from = %Nadia.Model.User{
      id: 1,
      first_name: "f_name",
      last_name: "l_name",
      username: "u_name"
    }

    update = %Nadia.Model.Update{
      update_id: :update_id,
      message: %Nadia.Model.Message{
        from: from
      }
    }

    assert %Marvin.Event.From{
             id: id,
             first_name: first_name,
             last_name: last_name,
             username: username,
             raw: ^from
           } = Telegram.from(update)

    assert id == from.id
    assert first_name == from.first_name
    assert last_name == from.last_name
    assert username == from.username
  end

  test "from/1 with callback_query extracts sender and converts it to marvin structure" do
    from = %Nadia.Model.User{
      id: 1,
      first_name: "f_name",
      last_name: "l_name",
      username: "u_name"
    }

    update = %Nadia.Model.Update{
      update_id: :update_id,
      callback_query: %Nadia.Model.CallbackQuery{
        from: from
      }
    }

    assert %Marvin.Event.From{
             id: id,
             first_name: first_name,
             last_name: last_name,
             username: username,
             raw: ^from
           } = Telegram.from(update)

    assert id == from.id
    assert first_name == from.first_name
    assert last_name == from.last_name
    assert username == from.username
  end
end
