defmodule Marvin.Telegram.KeyboardTest do
  use ExUnit.Case, async: true

  alias Marvin.Telegram.Keyboard
  alias ExGram.Model.{InlineKeyboardButton, InlineKeyboardMarkup}

  test "to_markup/1 converts marvin keyboard to ex_gram keyboard" do
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
