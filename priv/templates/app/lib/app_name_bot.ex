defmodule <%= @bot_namespace %> do
  @moduledoc false

  def handler do
    quote do
      use Marvin.Handler

      import Marvin.Event
    end
  end

  def matcher do
    quote do
      use Marvin.Matcher
    end
  end

  @doc """
  When used, dispatch to the appropriate handler and matcher
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
