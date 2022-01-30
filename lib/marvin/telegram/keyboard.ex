defmodule Marvin.Telegram.Keyboard do
  alias Marvin.Event
  alias Nadia.Model.{InlineKeyboardButton, InlineKeyboardMarkup}

  def to_markup(%Event.Keyboard{type: :inline, rows: rows}) do
    %InlineKeyboardMarkup{inline_keyboard: build_inline_markup(rows)}
  end

  defp build_inline_markup(rows) do
    Enum.map(rows, fn row ->
      Enum.map(row, fn %Event.Keyboard.InlineButton{} = item ->
        %InlineKeyboardButton{
          text: item.text,
          callback_data: item.callback_data,
          url: item.url
        }
      end)
    end)
  end
end
