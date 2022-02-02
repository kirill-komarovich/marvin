defmodule Marvin.Event.Processor do
  use GenServer, restart: :temporary

  alias Marvin.Event.Supervisor

  def start_link(update), do: GenServer.start_link(__MODULE__, update, [])

  def init(update), do: {:ok, update}

  def process(endpoint, adapter, updates) when is_list(updates) do
    Enum.each(updates, fn update -> process(endpoint, adapter, update) end)
  end

  def process(endpoint, adapter, update) do
    {:ok, pid} = Supervisor.start_child(update)

    GenServer.cast(pid, {:process, endpoint, adapter})
  end

  @event_prefix [:marvin, :update]

  def handle_cast({:process, endpoint, adapter}, update) do
    start_time = System.monotonic_time()

    :telemetry.execute(@event_prefix ++ [:start], %{system_time: System.system_time()}, %{
      endpoint: endpoint,
      adapter: adapter,
      update: update
    })

    try do
      update
      |> adapter.event()
      |> endpoint.call([])

      duration = System.monotonic_time() - start_time

      :telemetry.execute(@event_prefix ++ [:stop], %{duration: duration}, %{
        endpoint: endpoint,
        adapter: adapter,
        update: update
      })

      {:stop, :shutdown, update}
    rescue
      e ->
        duration = System.monotonic_time() - start_time

        :telemetry.execute(@event_prefix ++ [:exception], %{duration: duration}, %{
          endpoint: endpoint,
          adapter: adapter,
          update: update,
          kind: :exit,
          reason: e,
          stacktrace: __STACKTRACE__
        })

        reraise e, __STACKTRACE__
    end
  end
end
