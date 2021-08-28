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

  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :handlers, accumulate: true)

      import Marvin.Matcher
      import BubbleMatch.Sigil

      @before_compile Marvin.Matcher

      unquote(match_dispatch())
    end
  end

  defp match_dispatch do
    quote location: :keep do
      def call(event) do
        case match_handler(event) do
          {event, handler, opts} -> Marvin.Matcher.__call__(event, handler, opts)
          # TODO: handle exception with UnknownHandler?
          :error -> raise NoHandlerError, event: event
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    handlers = env.module |> Module.get_attribute(:handlers) |> Enum.reverse()

    quote do
      def match_handler(event) do
        start_time = System.monotonic_time()
        event_prefix = [:marvin, :matcher]
        :telemetry.execute(event_prefix ++ [:start], %{system_time: System.system_time()}, %{event: event})

        matched = do_match(event, unquote(handlers))

        duration = System.monotonic_time() - start_time
        :telemetry.execute(event_prefix ++ [:stop], %{duration: duration}, %{event: event})

        matched
      end

      @doc false
      def __handlers__, do: unquote(Macro.escape(handlers))
    end
  end

  def __call__(event, handler, opts) do
    :telemetry.execute(
      [:marvin, :matcher_dispatch, :start],
      %{system_time: System.system_time()},
      %{event: event, handler: handler}
    )

    # TODO: handle exceptions
    handler.call(event, opts)
  end

  def do_match(event, handlers) do
    Enum.find_value(handlers, :error, fn
      {handler, {pattern, opts}} ->
        case Marvin.Matcher.Matcherable.match(pattern, event, opts) do
          {:match, params} ->
            {
              Marvin.Event.update_params(event, params),
              handler,
              opts
            }

          :nomatch ->
            false
        end
    end)
  end

  defmacro handle(pattern, handler, opts \\ []) do
    pattern = pattern |> Macro.expand(__CALLER__) |> Macro.escape()
    handler = handler |> Macro.expand(__CALLER__)
    opts = opts |> Macro.expand(__CALLER__)

    quote do
      @handlers {unquote(handler), {unquote(pattern), unquote(opts)}}
    end
  end
end
