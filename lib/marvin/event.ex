defmodule Marvin.Event do
  @type adapter :: module()
  @type assigns :: %{optional(atom) => any()}
  @type text :: string()
  @type raw_event :: any()

  @type t :: %__MODULE__{
          adapter: adapter,
          assigns: assigns,
          text: text,
          raw_event: raw_event
        }

  defstruct [
    :adapter,
    :raw_event,
    :text,
    assigns: %{}
  ]

  def send_message(event = %__MODULE__{adapter: adapter} = event, text, opts \\ []) do
    adapter.send_message(event, text, opts)
  end
end
