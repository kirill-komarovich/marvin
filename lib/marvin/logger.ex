defmodule Marvin.Logger do
  require Logger

  def install do
    handlers = %{
      [:marvin, :endpoint, :start] => &marvin_endpoint_start/4,
      [:marvin, :endpoint, :stop] => &marvin_endpoint_stop/4,
      [:marvin, :matcher_dispatch, :start] => &marvin_matcher_dispatch_start/4
    }

    for {key, fun} <- handlers do
      :telemetry.attach({__MODULE__, key}, key, fun, :ok)
    end
  end

  def duration(duration) do
    duration = System.convert_time_unit(duration, :native, :microsecond)

    if duration > 1000 do
      [duration |> div(1000) |> Integer.to_string(), "ms"]
    else
      [Integer.to_string(duration), "µs"]
    end
  end

  defp marvin_endpoint_start(_, _, %{event: event}, _) do
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
      event_id: event.event_id
    )
  end

  defp marvin_endpoint_stop(_, %{duration: duration}, %{event: event}, _) do
    Logger.log(
      :info,
      fn ->
        ["Finished in ", duration(duration)]
      end,
      event_id: event.event_id
    )
  end

  defp marvin_matcher_dispatch_start(_, _, metadata, _) do
    %{handler: handler, event: event} = metadata

    Logger.log(
      :info,
      fn ->
        ["Processing with ", inspect(handler), ?\n, "  Params: ", inspect(event.params)]
      end,
      event_id: event.event_id
    )
  end
end