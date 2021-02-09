defmodule Marvin.Event.Supervisor do
  alias Marvin.Event.Processor

  def start_link() do
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  def start_child(update) do
    DynamicSupervisor.start_child(__MODULE__, {Processor, update})
  end

  def child_spec() do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end
end
