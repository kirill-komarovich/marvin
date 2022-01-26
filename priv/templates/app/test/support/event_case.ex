defmodule <%= @bot_namespace %>.EventCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Marvin.Event
      import Marvin.Test

      @endpoint <%= @endpoint_module %>
    end
  end

  setup _tags do
    {:ok, event: Marvin.Test.event()}
  end
end
