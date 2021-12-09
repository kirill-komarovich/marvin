defmodule Marvin.Event.KeyboardTest do
  use ExUnit.Case, async: true

  alias Marvin.Event.Keyboard

  test "new/1 with `reply` type returns empty reply keyboard" do
    assert %Keyboard{type: :reply, rows: [[]]} = Keyboard.new(:reply)
  end

  test "new/1 with `inline` type returns empty inline keyboard" do
    assert %Keyboard{type: :inline, rows: [[]]} = Keyboard.new(:inline)
  end

  test "button/2 with reply keyboard adds reply button to the last row with given opts " do
    keyboard = %Keyboard{type: :reply}
    text = "some text"

    assert %Keyboard{rows: [[%Keyboard.ReplyButton{text: ^text}]]} =
             Keyboard.button(keyboard, text: text)
  end

  test "button/2 with inline keyboard adds inline to the last row with given opts " do
    keyboard = %Keyboard{type: :inline}
    text = "some text"

    assert %Keyboard{rows: [[%Keyboard.InlineButton{text: ^text, callback_data: nil, url: nil}]]} =
             Keyboard.button(keyboard, text: text)
  end

  test "new_line/1 adds new empty row" do
    keyboard = %Keyboard{}

    assert %Keyboard{rows: [[], []]} = Keyboard.new_line(keyboard)
  end
end
