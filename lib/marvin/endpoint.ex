defmodule Marvin.Endpoint do
  @doc """
  Starts the endpoint supervision tree.
  """
  @callback start_link() :: Supervisor.on_start()

  @doc false
  defmacro __using__(opts) do
    quote do
      require Logger
      import Marvin.Endpoint
      @behaviour Marvin.Endpoint

      @before_compile Marvin.Endpoint

      unquote(config(opts))
      unquote(server())
    end
  end

  defp config(opts) do
    quote do
      @otp_app unquote(opts)[:otp_app] || raise("endpoint expects :otp_app to be given")

      Module.register_attribute(__MODULE__, :marvin_pollers, accumulate: true)
      Module.register_attribute(__MODULE__, :marvin_matcher, [])
    end
  end

  defp server() do
    quote location: :keep, unquote: false do
      @doc """
      Returns the child specification to start the endpoint
      under a supervision tree.
      """
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]},
          type: :supervisor
        }
      end

      @doc """
      Starts the endpoint supervision tree.
      """
      def start_link(opts \\ []) do
        Marvin.Endpoint.Supervisor.start_link(@otp_app, __MODULE__, opts)
      end
    end
  end

  defmacro __before_compile__(env) do
    pollers = Module.get_attribute(env.module, :marvin_pollers)
    matcher = Module.get_attribute(env.module, :marvin_matcher)

    quote do
      @event_prefix [:marvin, :endpoint]

      @doc """
      Delegates event to registered matcher.
      """
      def call(event) do
        start_time = System.monotonic_time()
        metadata = %{event: event}

        :telemetry.execute(
          @event_prefix ++ [:start],
          %{system_time: System.system_time()},
          metadata
        )

        event =
          Marvin.Event.register_before_send(event, fn event ->
            duration = System.monotonic_time() - start_time
            :telemetry.execute(@event_prefix ++ [:stop], %{duration: duration}, %{event: event})
            event
          end)

        unquote(matcher).call(event)
      end

      defoverridable call: 1

      def __pollers__(), do: unquote(pollers)
      def __matcher__(), do: unquote(matcher)
    end
  end

  @doc """
  Registers pollers for current endpoint.

  ## Examples

    defmodule MyAppBot.Endpoint do
      use Marvin.Endpoint, otp_app: :my_app

      poller Marvin.Poller.Telegram
    end
  """
  defmacro poller(mod, opts \\ []) do
    quote do
      @marvin_pollers {unquote(Macro.escape(mod)), unquote(opts)}
    end
  end

  @doc """
  Registers matcher for current endpoint.

  ## Examples

    defmodule MyAppBot.Endpoint do
      use Marvin.Endpoint, otp_app: :my_app

      matcher MyAppBot.Matcher
    end
  """
  defmacro matcher(mod) do
    quote do
      @marvin_matcher unquote(Macro.escape(mod))
    end
  end
end
