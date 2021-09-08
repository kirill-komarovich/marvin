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

    assert [%Nadia.Model.Update{}] = Telegram.get_updates(%{offset: offset})

    assert_receive {:get_updates, [offset: ^offset]}
  end

  test "send_message/3 sends message by chat_id" do
    chat_id = :chat_id

    private = %{chat_id: chat_id}

    text = "message"

    Telegram.send_message(%Marvin.Event{private: private}, text, [])

    assert_receive {:send_message, ^chat_id, ^text, []}
  end

  test "send_message/3 with reply option sends message by chat_id" do
    chat_id = :chat_id
    message_id = :message_id

    private = %{
      message_id: message_id,
      chat_id: chat_id
    }

    text = "message"

    Telegram.send_message(%Marvin.Event{private: private}, text, reply: true)

    assert_receive {:send_message, ^chat_id, ^text, [reply_to_message_id: ^message_id]}
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
end
