defmodule Marvin.Adapter do
  @doc false
  defmacro __using__(_) do
    quote do
      @behaviour Marvin.Adapter

      @callback get_updates(poller_state :: term) :: {:ok, updates :: term} | {:error, reason :: term}
    end
  end
end
