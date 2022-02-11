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
      use GenServer

      opts = unquote(opts)

      @otp_app opts[:otp_app] || raise("poller expects :otp_app to be given")
      @adapter opts[:adapter] || raise("poller expects :adapter to be given")

      @doc false
      def start_link(endpoint, opts \\ []) do
        GenServer.start_link(__MODULE__, {endpoint, opts}, name: __MODULE__)
      end

      @doc false
      @impl true
      def init({endpoint, _opts}) do
        :telemetry.execute(
          [:marvin, :poller, :start],
          %{system_time: System.system_time()},
          %{adapter: @adapter}
        )

        schedule_poll()

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
        result = Marvin.Poller.poll(@adapter, state, &update_state/2)

        schedule_poll()

        result
      end

      @doc ~S"""
      Poller state update function, used in end pollers
      """
      @spec update_state(map(), [term()]) :: map()
      def update_state(state, _updates), do: state

      defoverridable update_state: 2

      defp schedule_poll do
        Marvin.Poller.schedule_poll(self(), timeout())
      end

      defp timeout do
        Marvin.Poller.timeout(@otp_app, __MODULE__)
      end
    end
  end

  @doc """
  Polls for updates and sends them to event processor
  """
  @spec poll(atom(), map(), (map(), [term()] -> map())) :: {:noreply, map()}
  def poll(adapter, %{endpoint: endpoint} = state, state_updater) do
    case apply(adapter, :get_updates, [Enum.into(state, [])]) do
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

  @doc """
  Schedules poll for given pid
  """
  @spec schedule_poll(atom() | pid(), non_neg_integer()) :: reference()
  def schedule_poll(pid, timeout) do
    Process.send_after(pid, :poll, timeout)
  end

  @default_timeout 1000

  @doc """
  Returns configured timeout for current adapter

  ## Examples

    config.exs:
      ...
      config :your_app, YourPoller, timeout: 100

    iex> Marvin.Poller.timeout(:your_app, YourPoller)
    100
  """
  @spec timeout(atom(), atom()) :: non_neg_integer()
  def timeout(otp_app, poller_mod) do
    otp_app
    |> Application.get_env(poller_mod, [])
    |> Keyword.get(:timeout, @default_timeout)
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
