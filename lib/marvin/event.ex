defmodule Marvin.Event do
  @moduledoc ~S"""
  This module defines a struct and the main functions for working with events.
  """

  @type adapter :: module()
  @type assigns :: %{optional(atom()) => term()}
  @type params :: %{optional(binary()) => term()}
  @type platform :: atom()
  @type text :: binary()
  @type owner :: pid()
  @type raw_event :: term()
  @type before_send_callback :: (t() -> t())
  @type before_send :: [before_send_callback()]

  @type t :: %__MODULE__{
          adapter: adapter(),
          platform: platform(),
          raw_event: raw_event(),
          text: text(),
          owner: owner(),
          params: params(),
          assigns: assigns(),
          private: assigns(),
          before_send: before_send(),
          halted: boolean()
        }

  defstruct adapter: Marvin.MissingAdapter,
            platform: nil,
            raw_event: nil,
            text: "",
            owner: nil,
            params: %{},
            assigns: %{},
            private: %{},
            before_send: [],
            halted: false

  @doc """
  Sends text message with current adapter

  ## Examples

    iex> send_message(event, "Hello!")
    iex> send_message(event, "Hello!", reply: true)
    iex> send_message(event, "Hello!", keyboard: keyboard)

  """
  @spec send_message(t(), binary(), keyword) :: t()
  def send_message(%__MODULE__{adapter: adapter} = event, text, opts \\ []) do
    event = run_before_send(event)

    adapter.send_message(event, text, opts)

    event
  end

  @doc """
  Sends list of text messages with current adapter

  ## Examples

    iex> send_messages(event, [{"Hello!", reply: true}, "how are you?")
    iex> send_messages(event, ["Hello!", "how are you?"], reply: true)

  """
  @spec send_messages(t(), [{binary(), keyword()} | binary()]) :: t()
  def send_messages(%__MODULE__{adapter: adapter} = event, messages, opts \\ []) do
    # TODO: change to multi(&handler/1) API?
    event = run_before_send(event)

    Enum.each(messages, fn
      {text, message_opts} ->
        adapter.send_message(event, text, message_opts ++ opts)

      text when is_binary(text) ->
        adapter.send_message(event, text, opts)
    end)

    event
  end

  @doc """
  Edit message with current adapter

  ## Examples

    iex> edit_message(event, "Hello!")
    iex> edit_message(event, "Hello!", keyboard: keyboard)

  """
  @spec edit_message(event :: t(), text :: binary(), opts :: keyword()) :: t()
  def edit_message(%__MODULE__{adapter: adapter} = event, text, opts \\ []) do
    event = run_before_send(event)

    adapter.edit_message(event, text, opts)

    event
  end

  @doc """
  Answers to received callback query

   ## Examples

    iex> answer_callback(event, "Hello!")
    iex> answer_callback(event, "Hello!", alert: true)

  """
  @spec answer_callback(event :: t(), text :: binary(), opts :: keyword()) :: t()
  def answer_callback(%__MODULE__{adapter: adapter} = event, text, opts \\ []) do
    event = run_before_send(event)

    adapter.answer_callback(event, text, opts)

    event
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

  ## Examples

    iex> event.params
    %{}
    iex> update_params(event, %{"param" => "value"})
    iex> event.params
    %{"param" => "value"}

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
  Assigns a new **assigns** key and value in the event.

  ## Examples

      iex> event.assigns[:assigns_key]
      nil
      iex> event = put_assigns(event, :assigns_key, :value)
      iex> event.put_assigns[:assigns_key]
      :value

  """
  @spec put_assigns(t(), atom(), term()) :: t()
  def put_assigns(%__MODULE__{assigns: assigns} = event, key, value) when is_atom(key) do
    %{event | assigns: Map.put(assigns, key, value)}
  end

  @doc """
  Assigns multiple values to keys in the event.
  Equivalent to multiple calls to `put_assigns/3`.

  ## Examples

      iex> event.assigns[:assigns_key]
      nil
      iex> event = merge_assigns(event, assigns_key: :value)
      iex> event.assigns[:assigns_key]
      :value

  """
  @spec merge_assigns(t(), keyword()) :: t()
  def merge_assigns(%__MODULE__{assigns: assigns} = event, keyword) when is_list(keyword) do
    %{event | assigns: Enum.into(keyword, assigns)}
  end

  @doc """
  Assigns a new **private** key and value in the event.

  ## Examples

      iex> event.private[:private_key]
      nil
      iex> event = put_private(event, :private_key, :value)
      iex> event.private[:private_key]
      :value

  """
  @spec put_private(t(), atom(), term()) :: t()
  def put_private(%__MODULE__{private: private} = event, key, value) when is_atom(key) do
    %{event | private: Map.put(private, key, value)}
  end

  @doc """
  Assigns multiple **private** keys and values in the event.
  Equivalent to multiple `put_private/3` calls.

  ## Examples
      iex> event.private[:private_key]
      nil
      iex> event = merge_private(event, private_key: :value)
      iex> event.private[:private_key]
      :value

  """
  @spec merge_private(t(), keyword()) :: t()
  def merge_private(%__MODULE__{private: private} = event, keyword) when is_list(keyword) do
    %{event | private: Enum.into(keyword, private)}
  end

  @doc """
  Marks event as halted
  ## Examples:

    iex> event.halted
    false
    iex> halt(event)
    iex> event.halted
    true

  """
  @spec halt(t()) :: t()
  def halt(%__MODULE__{} = event) do
    %{event | halted: true}
  end

  @doc """
  Puts sender to event assigns as %Marvin.Event.From{} under :from key
  ## Examples:

    iex> put_from(event)
    iex> event,assigns[:from]
    %Marvin.Event.From{}

  """
  @spec put_from(t()) :: t()
  def put_from(%__MODULE__{adapter: adapter, raw_event: raw_event} = event) do
    put_assigns(event, :from, adapter.from(raw_event))
  end
end
