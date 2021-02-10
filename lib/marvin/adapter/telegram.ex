defmodule Marvin.Adapter.Telegram do
  use Marvin.Adapter

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
  def event(event) do
    %Marvin.Event{
      __adapter__: __MODULE__,
      platform: :telegram,
      text: event.message.text,
      raw_event: event
    }
  end

  defp run_command(command, args \\ []) do
    Application.ensure_all_started(:nadia)

    apply(Nadia, command, args)
  end
end
