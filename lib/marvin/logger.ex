defmodule Marvin.Logger do
  require Logger

  @doc false
  def install do
    handlers = %{
      [:marvin, :poller, :start] => &__MODULE__.marvin_poller_start/4,
      [:marvin, :poller, :poll, :error] => &__MODULE__.marvin_poller_poll_error/4,
      [:marvin, :endpoint, :start] => &__MODULE__.marvin_endpoint_start/4,
      [:marvin, :endpoint, :stop] => &__MODULE__.marvin_endpoint_stop/4,
      [:marvin, :matcher_dispatch, :start] => &__MODULE__.marvin_matcher_dispatch_start/4
    }

    for {key, fun} <- handlers do
      :telemetry.attach({__MODULE__, key}, key, fun, :ok)
    end
  end

  @doc false
  def duration(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      [duration |> div(1000) |> Integer.to_string(), "ms"]
    else
      [Integer.to_string(duration), "µs"]
    end
  end

  @doc false
  def marvin_poller_start(_, _, %{adapter: adapter}, _) do
    Logger.log(:info, fn -> ["Start poll with", ?\s, apply(adapter, :name, [])] end, [])
  end

  @doc false
  def marvin_poller_poll_error(_, _, %{adapter: adapter, error: error}, _) do
    Logger.log(
      :error,
      fn -> ["Error while polling", ?\s, apply(adapter, :name, []), ?:, ?\s, inspect(error)] end,
      []
    )
  end

  @doc false
  def marvin_endpoint_start(_, _, %{event: event}, _) do
    Logger.log(
      :info,
      fn ->
        %{text: text, platform: platform} = event

        [
          "Get",
          ?\s,
          Atom.to_string(platform),
          ?\s,
          "update",
          ?\n,
          "  Text:  ",
          text
        ]
      end,
      event_id: event.private[:event_id]
    )
  end

  @doc false
  def marvin_endpoint_stop(_, %{duration: duration}, %{event: event}, _) do
    Logger.log(
      :info,
      fn ->
        ["Finished in ", duration(duration), ?\n]
      end,
      event_id: event.private[:event_id]
    )
  end

  @doc false
  def marvin_matcher_dispatch_start(_, _, metadata, _) do
    %{handler: handler, event: event} = metadata

    Logger.log(
      :info,
      fn ->
        ["Processing with ", inspect(handler), ?\n, "  Params: ", inspect(event.params)]
      end,
      event_id: event.private[:event_id]
    )
  end
end
