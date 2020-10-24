defmodule Mix.Tasks.Mvn.Poll do
  @moduledoc """
    Mix task for starting polling updates
  """
  use Mix.Task
  alias Mix.Tasks.Run

  def run(args) do
    Application.put_env(:marvin, :polling, true, persistent: true)
    Run.run run_args() ++ args
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end
end
