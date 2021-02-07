defmodule Marvin.Poller do
  @moduledoc ~S"""

  """

  alias Marvin.Event

  @doc false
  defmacro __using__(opts) do
    quote do
      import Marvin.Poller

      unquote(config(opts))
      unquote(poller())
    end
  end

  def config(opts) do
    quote do
      require Logger

      use GenServer

      opts = unquote(opts)

      @adapter opts[:adapter] || raise("poller expects :adapter to be given")
      @timeout opts[:timeout] || 1000

      def start_link(endpoint, opts \\ []) do
        GenServer.start_link(__MODULE__, {endpoint, opts}, name: @adapter)
      end

      @impl true
      def init({endpoint, _opts}) do
        Logger.info("Start poll with #{adapter_name()}")

        :timer.send_interval(@timeout, :poll)

        {:ok, %{endpoint: endpoint}}
      end

      defp adapter_name, do: apply(@adapter, :name, [])

      defoverridable init: 1
    end
  end

  def poller() do
    quote location: :keep, unquote: false do
      @doc false
      def child_spec(opts) do
        Marvin.Poller.__child_spec__(__MODULE__, opts)
      end

      @impl true
      def handle_info(:poll, %{endpoint: endpoint} = state) do
        case apply(@adapter, :get_updates, [state]) do
          {:ok, updates} -> process_updates(endpoint, @adapter, updates)
          {:error, error} -> process_error(error)
        end

        {:noreply, state}
      end
    end
  end

  def process_updates(endpoint, adapter, updates) when is_list(updates) do
    Enum.each(updates, fn update ->
      event = apply(adapter, :event, [update])
      # TODO: spawn process for each update?
      endpoint.call(event)
    end)
  end

  def process_error(error) do
    IO.inspect(error)
  end

  def __child_spec__(handler, opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    args = [endpoint]

    %{
      id: handler,
      start: {handler, :start_link, args}
    }
  end
end
