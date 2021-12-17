defmodule Marvin.Pipeline.Builder do
  @type pipeline :: module() | atom()

  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Marvin.Pipeline
      @pipeline_builder_opts unquote(opts)

      def init(opts), do: opts

      def call(event, opts), do: pipeline_builder_call(event, opts)

      defoverridable Marvin.Pipeline

      import Marvin.Event
      import Marvin.Pipeline.Builder, only: [plug: 1, plug: 2]

      Module.register_attribute(__MODULE__, :pipelines, accumulate: true)
      @before_compile Marvin.Pipeline.Builder
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    pipelines = Module.get_attribute(env.module, :pipelines)

    builder_opts = Module.get_attribute(env.module, :pipeline_builder_opts)
    {event, body} = Marvin.Pipeline.Builder.compile(env, pipelines, builder_opts)

    compile_time =
      for triplet <- pipelines,
          {pipeline, _, _} = triplet,
          match?(~c"Elixir." ++ _, Atom.to_charlist(pipeline)) do
        quote(do: unquote(pipeline).__info__(:module))
      end

    quote do
      unquote_splicing(compile_time)
      defp pipeline_builder_call(unquote(event), opts), do: unquote(body)
    end
  end

  defmacro plug(pipeline, opts \\ []) do
    pipeline = Macro.expand(pipeline, __CALLER__)

    quote do
      @pipelines {unquote(pipeline), unquote(opts), true}
    end
  end

  # TODO: builder_opts macro

  @spec compile(
          Macro.Env.t(),
          [{Marvin.Pipeline.Builder.pipeline(), Marvin.Pipeline.opts(), Macro.t()}],
          Keyword.t()
        ) :: {Macro.t(), Macro.t()}
  def compile(env, pipelines, builder_opts) do
    event = quote do: event

    ast =
      Enum.reduce(pipelines, event, fn {pipeline, opts, guards}, acc ->
        {pipeline, opts, guards}
        |> init_pipeline()
        |> quote_pipeline(acc, env, builder_opts)
      end)

    {event, ast}
  end

  defp init_pipeline({pipeline, opts, guards}) do
    case Atom.to_charlist(pipeline) do
      ~c"Elixir." ++ _ -> init_module_pipeline(pipeline, opts, guards)
      _ -> init_fun_pipeline(pipeline, opts, guards)
    end
  end

  defp init_module_pipeline(pipeline, opts, guards) do
    initialized_opts = pipeline.init(opts)

    if function_exported?(pipeline, :call, 2) do
      {:module, pipeline, escape(initialized_opts), guards}
    else
      raise ArgumentError, "#{inspect(pipeline)} pipeline must implement call/2"
    end
  end

  defp init_fun_pipeline(pipeline, opts, guards) do
    {:function, pipeline, escape(opts), guards}
  end

  defp escape(opts) do
    Macro.escape(opts, unquote: true)
  end

  defp quote_pipeline({:module, pipeline, opts, guards}, acc, env, builder_opts) do
    call = quote_pipeline(:module, pipeline, opts, guards, acc, env, builder_opts)

    quote do
      require unquote(pipeline)
      unquote(call)
    end
  end

  defp quote_pipeline({type, pipeline, opts, guards}, acc, env, builder_opts) do
    quote_pipeline(type, pipeline, opts, guards, acc, env, builder_opts)
  end

  defp quote_pipeline(type, pipeline, opts, guards, acc, env, builder_opts) do
    call =
      quote_pipeline_call(type, pipeline, opts)
      |> compile_guards(guards)

    error_message =
      case type do
        :module -> "expected #{inspect(pipeline)}.call/2 to return a Marvin.Event"
        :function -> "expected #{pipeline}/2 to return a Marvin.Event"
      end <> ", all pipelines must receive a event and return a event"

    quote generated: true do
      case unquote(call) do
        %Marvin.Event{halted: true} = event ->
          unquote(log_halt(type, pipeline, env, builder_opts[:log_on_halt]))
          event

        %Marvin.Event{} = event ->
          unquote(acc)

        other ->
          raise unquote(error_message) <> ", got: #{inspect(other)}"
      end
    end
  end

  defp quote_pipeline_call(:function, pipeline, opts) do
    quote do: unquote(pipeline)(event, unquote(opts))
  end

  defp quote_pipeline_call(:module, pipeline, opts) do
    quote do: unquote(pipeline).call(event, unquote(opts))
  end

  defp compile_guards(call, true), do: call

  defp compile_guards(call, guards) do
    quote do
      case true do
        true when unquote(guards) -> unquote(call)
        true -> event
      end
    end
  end

  defp log_halt(_, _, _, nil), do: nil

  defp log_halt(pipeline_type, pipeline, env, level) do
    message =
      case pipeline_type do
        :module -> "#{inspect(env.module)} halted in #{inspect(pipeline)}.call/2"
        :function -> "#{inspect(env.module)} halted in #{inspect(pipeline)}/2"
      end

    quote do
      require Logger
      _ = Logger.unquote(level)(unquote(message))
    end
  end
end
