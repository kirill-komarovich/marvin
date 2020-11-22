defmodule Marvin.Adapter.Telegram do
  use Marvin.Adapter

  @impl true
  def get_updates(_) do
    run_command(:get_updates)
  end

  @impl true
  def event(event) do
    %Marvin.Event{
      adapter: Marvin.Adapter.Telegram,
      raw_event: event
    }
  end

  defp run_command(command, args \\ []) do
    Application.ensure_all_started(:nadia)

    apply(Nadia, command, args)
  end
end
