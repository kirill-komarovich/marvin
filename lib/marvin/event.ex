defmodule Marvin.Event do
  @type adapter :: module()
  @type params :: map()
  @type raw_event :: map()

  @type t :: %__MODULE__{
          adapter: adapter,
          assigns: assigns,
          raw_event: raw_event
        }

  defstruct [:adapter, :raw_event, assigns: %{}]

  defprotocol Eventable do
    @doc "Converts data to Marvin.Event"
    def to_event(event)
  end

  def to_event(data), do: Eventable.to_event(data)
end
