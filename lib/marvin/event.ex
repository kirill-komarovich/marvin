defmodule Marvin.Event do
  @type adapter :: module()
  @type assigns :: map()
  @type raw_event :: map()

  @type t :: %__MODULE__{
          adapter: adapter,
          assigns: assigns,
          raw_event: raw_event
        }

  defstruct [:adapter, :raw_event, assigns: %{}]
end
