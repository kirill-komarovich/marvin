defmodule Marvin.Event do
  @moduledoc ~S"""
  This module defines a struct and the main functions for working with events.
  """

  @type adapter :: module()
  @type assigns :: %{optional(atom()) => any()}
  @type params :: %{optional(String.t()) => any()}
  @type platform :: atom()
  @type text :: String.t()
  @type raw_event :: any()
  @type before_send_callback :: (t() -> t())
  @type before_send :: [before_send_callback()]

  @type t :: %__MODULE__{
          adapter: adapter(),
          platform: platform(),
          raw_event: raw_event(),
          text: text(),
          params: params(),
          assigns: assigns(),
          private: assigns(),
          before_send: before_send()
        }

  defstruct adapter: Marvin.MissingAdapter,
            platform: nil,
            raw_event: nil,
            text: "",
            params: %{},
            assigns: %{},
            private: %{},
            before_send: []

  @doc """
  Sends text message with current adapter

  ## Example:

    #{__MODULE__}.send_message(event, "Hello!", reply: true)

  """
  @spec send_message(t, String.t(), keyword) :: term
  def send_message(%__MODULE__{adapter: adapter} = event, text, opts \\ []) do
    event = run_before_send(event)

    apply(adapter, :send_message, [event, text, opts])
  end

  defp run_before_send(%__MODULE__{before_send: before_send} = event) do
    Enum.reduce(before_send, event, & &1.(&2))
  end

  @doc """
  Adds callback function that accepts and returns event

  ## Example:

    #{__MODULE__}.register_before_send(event, fn event ->
      IO.puts event.text
      event
    end)

  """
  @spec register_before_send(t(), before_send_callback()) :: t()
  def register_before_send(%__MODULE__{before_send: before_send} = event, callback)
      when is_function(callback, 1) do
    %{event | before_send: [callback | before_send]}
  end

  @doc """
  Updates params attribute of current event

  ## Example:

    #{__MODULE__}.update_params(event, %{"param" => "value"})

  """
  @spec update_params(t(), params()) :: t()
  def update_params(event, new_params)

  def update_params(%__MODULE__{} = event, new_params) when map_size(new_params) == 0 do
    event
  end

  def update_params(%__MODULE__{params: params} = event, new_params) when is_map(new_params) do
    %{event | params: Map.merge(params, new_params)}
  end

  @doc """
  Assigns a new **private** key and value in the event.

  ## Example:

    #{__MODULE__}.put_private(event, :private_key, :value)

  """
  @spec put_private(t(), atom(), term()) :: t()
  def put_private(%__MODULE__{private: private} = event, key, value) when is_atom(key) do
    %{event | private: Map.put(private, key, value)}
  end
end
