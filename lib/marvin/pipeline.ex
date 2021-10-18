defmodule Marvin.Pipeline do
  @type opts :: term()

  @callback init(opts) :: opts
  @callback call(event :: Marvin.Event.t(), opts) :: Marvin.Event.t()

  require Logger

  @spec run(
          Marvin.Event.t(),
          [{module, opts} | (Marvin.Event.t() -> Marvin.Event.t())],
          Keyword.t()
        ) ::
          Marvin.Event.t()
  def run(event, pipelines, opts \\ [])

  def run(%Marvin.Event{halted: true} = event, _pipelines, _opts), do: event

  def run(%Marvin.Event{} = event, pipelines, opts) do
    map(event, pipelines, Keyword.get(opts, :log_on_halt))
  end

  defp map(event, [{mod, opts} | pipelines], level) when is_atom(mod) do
    case mod.call(event, mod.init(opts)) do
      %Marvin.Event{halted: true} = event ->
        level && Logger.log(level, "Pipeline halted in #{inspect(mod)}.call/2")
        event

      %Marvin.Event{} = event ->
        map(event, pipelines, level)

      other ->
        raise "expected #{inspect(mod)} to return Marvin.Event, got: #{inspect(other)}"
    end
  end

  defp map(event, [fun | pipelines], level) when is_function(fun, 1) do
    case fun.(event) do
      %Marvin.Event{halted: true} = event ->
        level && Logger.log(level, "Pipeline halted in #{inspect(fun)}")
        event

      %Marvin.Event{} = event ->
        map(event, pipelines, level)

      other ->
        raise "expected #{inspect(fun)} to return Marvin.Event, got: #{inspect(other)}"
    end
  end

  defp map(event, [], _level), do: event
end
