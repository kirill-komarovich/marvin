defmodule Marvin.Test.Notifier do
  def notify(pid, event) do
    send(pid, event)
  end

  def notify_callers(event) do
    for pid <- callers() do
      send(pid, event)
    end
  end

  defp callers do
    Enum.uniq([self() | List.wrap(Process.get(:"$callers"))])
  end
end
