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
      def call(event) do
        case __matcher__().call(event) do
          nil -> Logger.info("Can't find handler") # TODO: Better process of unknown events
          handler -> process_event(handler, event)
        end
      end

      defoverridable call: 1

      def __pollers__(), do: unquote(Macro.escape(pollers))
      def __matcher__(), do: unquote(Macro.escape(matcher))

      defp process_event(handler, event) do
        Logger.info("Processing #{event.adapter.name()} update by #{handler}")

        {ums, _} = :timer.tc(handler, :call, [event])

        Logger.info("Finished in #{formatted_diff(ums)}")
      end

      defp formatted_diff(diff) when diff > 1000, do: [to_string(diff / 1000), "ms"]
      defp formatted_diff(diff), do: [to_string(diff), "µs"]
    end
  end

  defmacro poller(mod, opts \\ []) do
    quote do
      @marvin_pollers {unquote(mod), unquote(opts)}
    end
  end

  defmacro matcher(mod) do
    quote do
      @marvin_matcher unquote(mod)
    end
  end
end
