defmodule Marvin.Handler do
  @moduledoc """
    Base handler behaviour
  """

  alias Marvin.Event

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)
    end
  end

  @callback call(Event.t()) :: any
end
