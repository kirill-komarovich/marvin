defmodule Marvin.Matcher do
  @moduledoc """
    Module for matching handlers

    ##Example

    defmodule Marvin.Matcher do
      use Marvin.Matcher

      handle ~r/.*/, Marvin.Handlers.HelloHandler
    end
  """

  defprotocol Matcherable do
    @spec match?(pattern :: term, event :: Marvin.Event.t()) :: boolean()
    def match?(pattern, event)
  end

  defimpl Matcherable, for: Regex do
    def match?(pattern, %Marvin.Event{text: text}) do
      Regex.match?(pattern, text)
    end
  end

  defimpl Matcherable, for: BitString do
    def match?(pattern, %Marvin.Event{text: text}) do
      String.contains?(text, pattern)
    end
  end

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :handlers, accumulate: true)

      import Marvin.Matcher
      @before_compile Marvin.Matcher
    end
  end

  defmacro __before_compile__(env) do
    handlers = env.module |> Module.get_attribute(:handlers) |> Enum.reverse()

    quote do
      def call(event) do
        do_match(unquote(handlers), event)
      end

      @doc false
      def __handlers__, do: unquote(handlers)
    end
  end

  defmacro handle(pattern, handler) do
    quote do
      @handlers {unquote(Macro.escape(pattern)), unquote(Macro.escape(handler))}
    end
  end

  def do_match(handlers, event) do
    Enum.find_value(handlers, fn {pattern, handler} ->
      if Matcherable.match?(pattern, event), do: handler
    end)
  end
end
