defmodule Marvin.Adapter do
  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Marvin.Adapter

      @name unquote(opts[:name]) || __MODULE__

      def name do
        @name |> to_string() |> String.split(".") |> List.last() |> String.capitalize()
      end
    end
  end

  @callback send_message(event :: Marvin.Event.t(), text :: String.t(), opts :: keyword()) ::
              term()
  @callback edit_message(event :: Marvin.Event.t(), text :: String.t(), opts :: keyword()) ::
              term()
  @callback answer_callback(event :: Marvin.Event.t(), text :: String.t(), opts :: keyword()) ::
              term()
end
