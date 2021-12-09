defmodule Marvin.Event.Keyboard.ReplyButton do
  defstruct [:text]

  def new(attrs) do
    struct(__MODULE__, attrs)
  end
end
