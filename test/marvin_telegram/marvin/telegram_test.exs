defmodule Marvin.TelegramTest do
  use ExUnit.Case, async: true

  alias Marvin.Telegram

  test "name/0 returns adapter name" do
    assert "Telegram" = Telegram.name()
  end

  test "get_updates/1 returns list of updates" do
    offset = 1

    assert [%ExGram.Model.Update{}] = Telegram.get_updates(offset: offset)

    assert_receive {:telegram, :get_updates, [offset: ^offset]}
  end

  test "send_message/3 sends message by chat_id inside event" do
    chat_id = :chat_id
    text = "message"

    Telegram.send_message(%Marvin.Event{private: %{chat_id: chat_id}}, text, [])

    assert_receive {:telegram, :send_message, ^chat_id, ^text, []}
  end

  test "send_message/3 sends message by chat_id" do
    chat_id = :chat_id
    text = "message"

    Telegram.send_message(chat_id, text, [])

    assert_receive {:telegram, :send_message, ^chat_id, ^text, []}
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

    assert_receive {:telegram, :send_message, ^chat_id, ^text, [reply_to_message_id: ^message_id]}
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

    assert_receive {:telegram, :send_message, ^chat_id, ^text, [reply_to_message_id: ^message_id]}
  end

  test "send_message/3 with keyboard option sends message with reply markup" do
    chat_id = :chat_id
    text = "message"
    keyboard = %Marvin.Event.Keyboard{type: :inline}
    markup = %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: [[]]}

    Telegram.send_message(%Marvin.Event{private: %{chat_id: chat_id}}, text, keyboard: keyboard)

    assert_receive {:telegram, :send_message, ^chat_id, ^text, [reply_markup: ^markup]}
  end

  test "send_message/3 with unknown option sends message by chat_id" do
    chat_id = :chat_id
    text = "message"

    Telegram.send_message(%Marvin.Event{private: %{chat_id: chat_id}}, text, unknown: :value)

    assert_receive {:telegram, :send_message, ^chat_id, ^text, []}
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

    assert_receive {:telegram, :edit_message_text, ^chat_id, ^message_id, nil, ^text, []}
  end

  test "edit_message/3 edits messages by chat_id and message_id" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"

    Telegram.edit_message(chat_id, message_id, nil, text, [])

    assert_receive {:telegram, :edit_message_text, ^chat_id, ^message_id, nil, ^text, []}
  end

  test "edit_message/3 with keyboard option edits messages by chat_id and message_id with reply markup" do
    chat_id = :chat_id
    message_id = :message_id
    text = "message"
    keyboard = %Marvin.Event.Keyboard{type: :inline}
    markup = %ExGram.Model.InlineKeyboardMarkup{inline_keyboard: [[]]}

    Telegram.edit_message(
      %Marvin.Event{private: %{chat_id: chat_id, message_id: message_id}},
      text,
      keyboard: keyboard
    )

    assert_receive {:telegram, :edit_message_text, ^chat_id, ^message_id, nil, ^text,
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

    assert_receive {:telegram, :edit_message_text, ^chat_id, ^message_id, nil, ^text, []}
  end

  test "answer_callback/3 sends callback answer by callback_id" do
    callback_id = :callback_id
    text = "alert"

    Telegram.answer_callback(
      %Marvin.Event{private: %{callback_id: callback_id}},
      text,
      []
    )

    assert_receive {:telegram, :answer_callback_query, ^callback_id,
                    [text: ^text, show_alert: false]}
  end

  test "answer_callback/3 with alert option sends callback answer by callback_id as alert" do
    callback_id = :callback_id
    text = "alert"

    Telegram.answer_callback(
      %Marvin.Event{private: %{callback_id: callback_id}},
      text,
      alert: true
    )

    assert_receive {:telegram, :answer_callback_query, ^callback_id,
                    [text: ^text, show_alert: true]}
  end

  test "event/1 converts ExGram.Model.Update to Marvin.Event" do
    update = %ExGram.Model.Update{
      update_id: :update_id,
      message: %ExGram.Model.Message{
        text: "text",
        entities: nil,
        message_id: :message_id,
        chat: %{
          id: :chat_id
        },
        from: %ExGram.Model.User{}
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

  test "event/1 with sticker converts ExGram.Model.Update to Marvin.Event" do
    update = %ExGram.Model.Update{
      update_id: :update_id,
      message: %ExGram.Model.Message{
        text: nil,
        sticker: %ExGram.Model.Sticker{emoji: "👍"},
        entities: nil,
        message_id: :message_id,
        chat: %{
          id: :chat_id
        },
        from: %ExGram.Model.User{}
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

  test "event/1 with edited message converts ExGram.Model.Update to Marvin.Event" do
    update = %ExGram.Model.Update{
      update_id: :update_id,
      edited_message: %{
        text: "text",
        entities: nil,
        message_id: :message_id,
        chat: %{
          id: :chat_id
        },
        from: %{}
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

  test "event/1 with command converts ExGram.Model.Update to Marvin.Event" do
    update = %ExGram.Model.Update{
      update_id: :update_id,
      message: %ExGram.Model.Message{
        text: "text",
        entities: [%{type: "bot_command"}],
        message_id: :message_id,
        chat: %{
          id: :chat_id
        },
        from: %ExGram.Model.User{}
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

  test "event/1 with callback_query ExGram.Model.Update to Marvin.Event" do
    update = %ExGram.Model.Update{
      update_id: :update_id,
      callback_query: %ExGram.Model.CallbackQuery{
        data: "some_data",
        message: %ExGram.Model.Message{
          text: "",
          entities: nil,
          message_id: :message_id,
          chat: %{
            id: :chat_id
          }
        },
        from: %ExGram.Model.User{}
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
    from = %ExGram.Model.User{
      id: 1,
      first_name: "f_name",
      last_name: "l_name",
      username: "u_name"
    }

    update = %ExGram.Model.Update{
      update_id: :update_id,
      message: %ExGram.Model.Message{
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
    from = %ExGram.Model.User{
      id: 1,
      first_name: "f_name",
      last_name: "l_name",
      username: "u_name"
    }

    update = %ExGram.Model.Update{
      update_id: :update_id,
      callback_query: %ExGram.Model.CallbackQuery{
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
