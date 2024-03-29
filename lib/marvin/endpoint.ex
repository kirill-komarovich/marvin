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

      use Marvin.Pipeline.Builder
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
      def start_link(_opts \\ []) do
        Marvin.Endpoint.Supervisor.start_link(@otp_app, __MODULE__)
      end
    end
  end

  defmacro __before_compile__(env) do
    pollers = Module.get_attribute(env.module, :marvin_pollers)

    quote do
      def __pollers__(), do: unquote(pollers)
    end
  end

  @doc """
  Registers pollers for current endpoint.

  ## Examples

    defmodule MyAppBot.Endpoint do
      use Marvin.Endpoint, otp_app: :my_app

      poller Marvin.Telegram.Poller
    end
  """
  defmacro poller(mod, opts \\ []) do
    quote do
      @marvin_pollers {unquote(Macro.escape(mod)), unquote(opts)}
    end
  end
end
