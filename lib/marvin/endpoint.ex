defmodule Marvin.Endpoint do
  @doc """
  Starts the endpoint supervision tree.
  """
  @callback start_link() :: Supervisor.on_start()

  @doc false
  defmacro __using__(opts) do
    quote do
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

    quote do
      def call(event, opts) do
      end

      defoverridable call: 2

      def __pollers__(), do: unquote(Macro.escape(pollers))
    end
  end

  defmacro poller(mod, opts \\ []) do
    quote do
      @marvin_pollers {unquote(mod), unquote(opts)}
    end
  end
end
