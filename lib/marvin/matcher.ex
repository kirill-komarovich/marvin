defmodule Marvin.Matcher do
  @moduledoc """
    Module for matching handlers

    ##Example

    defmodule Marvin.Matcher do
      use Marvin.Matcher

      handle ~r/.*/, Marvin.Handlers.HelloHandler
    end
  """

  defmodule NoHandlerError do
    @moduledoc """
    Exception raised when no handler is found.
    """
    defexception message: "no handler found", event: nil

    def exception(opts) do
      event = Keyword.fetch!(opts, :event)

      %NoHandlerError{
        message: "no handler found for #{event.platform} message: #{event.text}",
        event: event
      }
    end
  end

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

      unquote(match_dispatch())
    end
  end

  defp match_dispatch do
    quote location: :keep do
      def call(event) do
        %{text: text} = event

        case match_handler(event) do
          # TODO: handle exception with UnknownHandler?
          nil -> raise NoHandlerError, event: event
          handler -> Marvin.Matcher.__call__(event, handler)
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    handlers = env.module |> Module.get_attribute(:handlers) |> Enum.reverse()

    quote do
      def match_handler(event) do
        do_match(event, unquote(handlers))
      end

      @doc false
      def __handlers__, do: unquote(Macro.escape(handlers))

      def do_match(event, handlers) do
        Enum.find_value(handlers, fn {pattern, handler} ->
          if Matcherable.match?(pattern, event), do: handler
        end)
      end
    end
  end

  def __call__(event, handler) do
    metadata = %{event: event, handler: handler}

    :telemetry.execute(
      [:marvin, :matcher_dispatch, :start],
      %{system_time: System.system_time()},
      metadata
    )

    # TODO: handle exceptions
    # TODO: add update id for logging
    handler.call(event)
  end

  defmacro handle(pattern, handler) do
    quote do
      @handlers {unquote(Macro.escape(pattern)), unquote(Macro.escape(handler))}
    end
  end
end
