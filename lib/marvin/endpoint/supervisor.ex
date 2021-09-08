defmodule Marvin.Endpoint.Supervisor do
  require Logger

  use Supervisor

  alias Marvin.Event

  @doc """
  Starts the endpoint supervision tree.
  """
  def start_link(mod) do
    case Supervisor.start_link(__MODULE__, mod, name: mod) do
      {:ok, _} = ok ->
        ok

      {:error, _} = error ->
        error
    end
  end

  @impl true
  def init(mod) do
    children = event_children() ++ pollers_children(mod, polling?())

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp event_children do
    [Event.Supervisor.child_spec([])]
  end

  defp pollers_children(endpoint, polling?) do
    if polling? do
      Enum.map(endpoint.__pollers__(), fn {poller, opts} ->
        poller.child_spec([endpoint: endpoint] ++ opts)
      end)
    else
      []
    end
  end

  defp polling? do
    Application.get_env(:marvin, :serve_endpoints, false)
  end
end
