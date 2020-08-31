defmodule Marvin.Processor do
  @moduledoc """
    Marvin updates processor
  """
  require Logger

  defmacro __using__(opts) do
    quote do
      unquote(config(opts))
      unquote(processor())
    end
  end

  defp config(opts) do
    quote do
      @matcher unquote(opts)[:matcher] || raise "processor expects :matcher to be given"
    end
  end

  defp processor do
    quote location: :keep, unquote: false do
      use GenServer
      import Marvin.Processor

      @doc false
      def init(_), do: {:ok, nil}

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, nil, name: __MODULE__)
      end

      def process_update(update), do: GenServer.call(__MODULE__, {:process_update, update})

      def handle_call({:process_update, update}, _from, state) do
        @matcher.call(update)

        {:reply, :ok, state}
      end
    end
  end
end
