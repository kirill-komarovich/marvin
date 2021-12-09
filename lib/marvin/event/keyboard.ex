defmodule Marvin.Event.Keyboard do
  alias Marvin.Event.Keyboard.InlineButton
  alias Marvin.Event.Keyboard.ReplyButton

  defstruct rows: [[]], type: nil

  @types ~w[reply inline]a

  @button_types %{
    reply: ReplyButton,
    inline: InlineButton
  }

  def new(type) when type in @types do
    %__MODULE__{type: type}
  end

  def button(%__MODULE__{rows: rows, type: type} = keyboard, opts) do
    new_button = apply(Map.fetch!(@button_types, type), :new, [opts])
    [last | reversed_rows] = Enum.reverse(rows)

    rows = Enum.reverse([last ++ [new_button] | reversed_rows])

    %{keyboard | rows: rows}
  end

  def new_line(%__MODULE__{rows: rows} = keyboard) do
    %{keyboard | rows: rows ++ [[]]}
  end
end
