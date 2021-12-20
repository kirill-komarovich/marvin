defmodule Marvin.Adapter.Telegram.KeyboardTest do
  use ExUnit.Case, async: true

  alias Marvin.Adapter.Telegram.Keyboard
  alias Nadia.Model.{InlineKeyboardButton, InlineKeyboardMarkup}

  test "to_markup/1 converts marvin keyboard to nadia keyboard" do
    button = %Marvin.Event.Keyboard.InlineButton{
      text: "text",
      callback_data: "callback_data",
      url: "url"
    }

    keyboard = %Marvin.Event.Keyboard{type: :inline, rows: [[button]]}

    assert %InlineKeyboardMarkup{
             inline_keyboard: [
               [%InlineKeyboardButton{text: text, callback_data: callback_data, url: url}]
             ]
           } = Keyboard.to_markup(keyboard)

    assert text == button.text
    assert callback_data == button.callback_data
    assert url == button.url
  end
end