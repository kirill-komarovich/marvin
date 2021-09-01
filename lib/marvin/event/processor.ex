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

  def handle_cast({:process, endpoint, adapter}, update) do
    event = apply(adapter, :event, [update])
    endpoint.call(event)

    {:stop, :shutdown, update}
  end
end
