defmodule Marvin.Matcher do
  @moduledoc """
    Module for matching handlers

    ##Example

    defmodule Marvin.Matcher do
      use Marvin.Matcher

      handle ~r/.*/, Marvin.Handlers.HelloHandler
    end
  """

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :handlers, accumulate: true)

      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
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
    {pattern, handler} =
      Enum.find(handlers, fn {pattern, _} -> Regex.match?(pattern, event.text) end)

    handler
  end
end
