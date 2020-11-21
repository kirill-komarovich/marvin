defmodule Marvin.Adapter do
  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Marvin.Adapter

      @name unquote(opts[:name]) || __MODULE__

      def name do
        @name |> to_string() |> String.split(".") |> List.last |> String.capitalize
      end
    end
  end

  @callback get_updates(poller_state :: term) :: {:ok, updates :: term} | {:error, reason :: term}
end
