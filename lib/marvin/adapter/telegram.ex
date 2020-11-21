defmodule Marvin.Adapter.Telegram do
  use Marvin.Adapter

  defimpl Marvin.Event.Eventable, for: Nadia.Model.Update do
    def to_event(event) do
      %Marvin.Event{
        adapter: Marvin.Adapter.Telegram,
        raw_event: event
      }
    end
  end

  @impl true
  def get_updates(_) do
    run_command(:get_updates)
  end

  defp run_command(command, args \\ []) do
    Application.ensure_all_started(:nadia)

    apply(Nadia, command, args)
  end
end
