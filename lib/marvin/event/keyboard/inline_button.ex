defmodule Marvin.Event.Keyboard.InlineButton do
  defstruct [:text, callback_data: nil, url: nil]

  def new(attrs) do
    struct(__MODULE__, attrs)
  end
end
