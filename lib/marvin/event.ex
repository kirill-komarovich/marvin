defmodule Marvin.Event do
  @type adapter :: module()
  @type assigns :: %{optional(atom) => any()}
  @type params :: %{optional(atom) => any()}
  @type platform :: atom()
  @type text :: string()
  @type raw_event :: any()

  @type t :: %__MODULE__{
          __adapter__: adapter,
          platform: platform,
          assigns: assigns,
          params: params,
          text: text,
          raw_event: raw_event
        }

  defstruct [
    :__adapter__,
    :platform,
    :raw_event,
    :text,
    params: %{},
    assigns: %{}
  ]

  def send_message(event = %__MODULE__{__adapter__: adapter} = event, text, opts \\ []) do
    adapter.send_message(event, text, opts)
  end
end
