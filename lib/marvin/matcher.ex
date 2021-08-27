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
      @before_compile Marvin.Matcher

      # unquote(match_dispatch())
    end
  end

  defp match_dispatch do
    quote location: :keep do
      def call(event) do
        %{text: text} = event

        case match_handler(event) do
          # TODO: handle exception with UnknownHandler?
          :error -> raise NoHandlerError, event: event
          {handler, opts} -> Marvin.Matcher.__call__(event, handler, opts)
        end
      end
    end
  end

  defmacro __before_compile__(env) do
    handlers = env.module |> Module.get_attribute(:handlers) |> Enum.reverse() |> Macro.escape()

    quote do
      @doc false
      def __handlers__, do: unquote(handlers)

      unquote(Marvin.Matcher.Compiler.compile(handlers))
    end
  end

  def __call__(event, handler, opts) do
    metadata = %{event: event, handler: handler}

    :telemetry.execute(
      [:marvin, :matcher_dispatch, :start],
      %{system_time: System.system_time()},
      metadata
    )

    # TODO: handle exceptions
    # TODO: add update id for logging
    handler.call(event, opts)
  end

  def sigil_m(string, []) do
    {:ok, parsed, _, _, _, _} = Marvin.Matcher.Parser.pattern(string)
    parsed
  end

  defmacro handle(pattern, handler, opts \\ []) do
    pattern = pattern |> Macro.expand(__CALLER__)
    handler = handler |> Macro.expand(__CALLER__)
    opts = opts |> Macro.expand(__CALLER__)

    quote do
      @handlers {unquote(pattern), unquote(handler), unquote(opts)}
    end
  end
end
