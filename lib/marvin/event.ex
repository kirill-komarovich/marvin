defmodule Marvin.Event do
  @type adapter :: module()
  @type assigns :: %{optional(atom) => any()}
  @type params :: %{optional(atom) => any()}
  @type platform :: atom()
  @type text :: string()
  @type raw_event :: any()
  @type before_send :: [(t -> t)]

  @type t :: %__MODULE__{
          __adapter__: adapter,
          platform: platform,
          raw_event: raw_event,
          text: text,
          command?: boolean(),
          params: params,
          assigns: assigns,
          before_send: before_send
        }

  defstruct [
    :__adapter__,
    :platform,
    :raw_event,
    :text,
    command?: false,
    params: %{},
    assigns: %{},
    before_send: []
  ]

  def send_message(event = %__MODULE__{__adapter__: adapter} = event, text, opts \\ []) do
    event = run_before_send(event)

    adapter.send_message(event, text, opts)
  end

  @spec register_before_send(t, (t -> t)) :: t
  def register_before_send(%__MODULE__{before_send: before_send} = event, callback)
      when is_function(callback, 1) do
    %{event | before_send: [callback | before_send]}
  end

  defp run_before_send(%__MODULE__{before_send: before_send} = event) do
    Enum.reduce(before_send, event, & &1.(&2))
  end
end
