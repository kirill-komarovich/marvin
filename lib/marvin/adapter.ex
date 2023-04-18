defmodule Marvin.Adapter do
  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Marvin.Adapter

      @module_name __MODULE__ |> to_string() |> String.split(".") |> List.last()

      @name String.capitalize(unquote(opts[:name]) || @module_name)
      @platform unquote(opts[:platform]) || Macro.underscore(@module_name) |> String.to_atom()

      def name, do: @name

      def platform, do: @platform
    end
  end

  @callback send_message(event :: Marvin.Event.t(), text :: String.t(), opts :: keyword()) ::
              term()
  @callback edit_message(event :: Marvin.Event.t(), text :: String.t(), opts :: keyword()) ::
              term()
  @callback answer_callback(event :: Marvin.Event.t(), text :: String.t(), opts :: keyword()) ::
              term()
end
