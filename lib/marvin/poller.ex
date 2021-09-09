defmodule Marvin.Poller do
  @moduledoc ~S"""

  """

  @doc false
  defmacro __using__(opts) do
    quote do
      import Marvin.Poller

      unquote(config(opts))
      unquote(poller())
    end
  end

  @doc false
  def config(opts) do
    quote do
      require Logger

      use GenServer

      opts = unquote(opts)

      @adapter opts[:adapter] || raise("poller expects :adapter to be given")
      @timeout opts[:timeout] || 1000

      @doc false
      def start_link(endpoint, opts \\ []) do
        GenServer.start_link(__MODULE__, {endpoint, opts}, name: @adapter)
      end

      @doc false
      @impl true
      def init({endpoint, _opts}) do
        :telemetry.execute(
          [:marvin, :poller, :start],
          %{system_time: System.system_time()},
          %{adapter: @adapter}
        )

        :timer.send_interval(@timeout, :poll)

        {:ok, %{endpoint: endpoint}}
      end

      defoverridable init: 1
    end
  end

  @doc false
  def poller() do
    quote do
      @doc false
      def child_spec(opts) do
        Marvin.Poller.__child_spec__(__MODULE__, opts)
      end

      @impl true
      def handle_info(:poll, state) do
        Marvin.Poller.poll(@adapter, state, &update_state/2)
      end

      @doc ~S"""
      Poller state update function, used in end pollers
      """
      @spec update_state(map(), [term()]) :: map()
      def update_state(state, _updates), do: state

      defoverridable update_state: 2
    end
  end

  @doc """

  """
  @spec poll(atom(), map(), (map(), [term()] -> map())) :: {:noreply, map()}
  def poll(adapter, %{endpoint: endpoint} = state, state_updater) do
    case apply(adapter, :get_updates, [state]) do
      {:ok, updates} ->
        process_updates(endpoint, adapter, updates)
        new_state = state_updater.(state, updates)

        {:noreply, new_state}

      {:error, error} ->
        process_error(adapter, error)

        {:noreply, state}
    end
  end

  defp process_updates(endpoint, adapter, updates) do
    Marvin.Event.Processor.process(endpoint, adapter, updates)
  end

  defp process_error(adapter, error) do
    :telemetry.execute(
      [:marvin, :poller, :poll, :error],
      %{system_time: System.system_time()},
      %{adapter: adapter, error: error}
    )

    # TODO: raise exception?
  end

  @doc false
  def __child_spec__(handler, opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)

    %{
      id: handler,
      start: {handler, :start_link, [endpoint]}
    }
  end
end
