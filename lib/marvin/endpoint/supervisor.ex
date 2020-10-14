defmodule Marvin.Endpoint.Supervisor do
  require Logger
  use Supervisor

  @doc """
  Starts the endpoint supervision tree.
  """
  def start_link(otp_app, mod, opts \\ []) do
    IO.puts "Endpoint sup started"
    case Supervisor.start_link(__MODULE__, {otp_app, mod, opts}, name: mod) do
      {:ok, _} = ok ->
        ok
      {:error, _} = error ->
        error
    end
  end


  def init({otp_app, mod, opts}) do
    IO.puts "Endpoint init started"
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
