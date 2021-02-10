defmodule Marvin do
  @moduledoc """
  Documentation for `Marvin`.
  """

  use Application

  def start(_type, _args) do
    if Application.fetch_env!(:marvin, :logger) do
      Marvin.Logger.install()
    end

    Supervisor.start_link([], strategy: :one_for_one, name: Marvin.Supervisor)
  end
end
