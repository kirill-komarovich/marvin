defmodule Marvin.Pipeline.Logger do
  @behaviour Marvin.Pipeline

  @event_prefix [:marvin, :endpoint]

  def init(opts), do: opts

  def call(event, _opts) do
    start_time = System.monotonic_time()
    metadata = %{event: event}

    :telemetry.execute(
      @event_prefix ++ [:start],
      %{system_time: System.system_time()},
      metadata
    )

    Marvin.Event.register_before_send(event, fn event ->
      duration = System.monotonic_time() - start_time
      :telemetry.execute(@event_prefix ++ [:stop], %{duration: duration}, %{event: event})
      event
    end)
  end
end
