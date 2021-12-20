defmodule Marvin.Handler do
  @moduledoc """
    Base handler behaviour
  """

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Marvin.Pipeline
      @behaviour unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :pipelines, accumulate: true)

      import Marvin.Pipeline.Builder, only: [plug: 1, plug: 2]

      @before_compile Marvin.Handler

      def init(opts), do: opts

      def call(event, opts), do: handler_pipeline_call(event, opts)

      def handler_call(%Marvin.Event{} = event, _opts) do
        handle(event, event.params)
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    handler_call = {:handler_call, [], true}

    pipelines = [handler_call | Module.get_attribute(env.module, :pipelines)]

    {event, body} = Marvin.Pipeline.Builder.compile(env, pipelines, log_on_halt: :debug)

    quote do
      defp handler_pipeline_call(unquote(event), opts), do: unquote(body)
    end
  end

  @callback handle(event :: Marvin.Event.t(), params :: map()) :: Marvin.Event.t()
end
