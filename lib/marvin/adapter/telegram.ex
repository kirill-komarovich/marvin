defmodule Marvin.Adapter.Telegram do
  use Marvin.Adapter

  @command_entity_type "bot_command"

  @impl true
  def get_updates(opts) do
    offset = Map.get(opts, :offset)

    run_command(:get_updates, [[offset: offset]])
  end

  @impl true
  def send_message(%Marvin.Event{raw_event: raw_event}, text, opts) do
    options = []
    reply? = Keyword.get(opts, :reply)

    options =
      if reply? do
        options = Keyword.put(options, :reply_to_message_id, raw_event.message.message_id)
      else
        options
      end

    run_command(:send_message, [raw_event.message.chat.id, text, options])
  end

  @impl true
  def event(update) do
    command? =
      update.message.entities &&
        Enum.any?(update.message.entities, fn %{type: type} -> type == @command_entity_type end)

    %Marvin.Event{
      __adapter__: __MODULE__,
      platform: :telegram,
      text: update.message.text,
      command?: command?,
      event_id: event_id(update),
      raw_event: update
    }
  end

  defp event_id(%Nadia.Model.Update{update_id: update_id}) do
    update_id
  end

  defp run_command(command, args \\ []) do
    Application.ensure_all_started(:nadia)

    apply(Nadia, command, args)
  end
end
