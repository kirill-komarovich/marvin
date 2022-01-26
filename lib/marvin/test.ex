defmodule Marvin.Test do
  def event do
    Marvin.Adapter.Test.event(%Marvin.Event{})
  end

  def from(attrs) do
    Marvin.Adapter.Test.from(attrs)
  end

  defmacro handle(event, message, from \\ nil) do
    quote do
      Marvin.Test.dispatch(unquote(event), @endpoint, unquote(message), unquote(from))
    end
  end

  def dispatch(_event, endpoint, _message, _from) when is_nil(endpoint) do
    raise "no @endpoint set in test case"
  end

  def dispatch(event, endpoint, message, from) do
    event
    |> Marvin.Adapter.Test.event(message, from)
    |> endpoint.call(endpoint.init([]))
  end

  def sent_message(%Marvin.Event{owner: owner}, fun \\ nil) do
    message_action(:send_message, owner, fun)
  end

  def edited_message(%Marvin.Event{owner: owner}, fun \\ nil) do
    message_action(:edit_message, owner, fun)
  end

  def answered_callback(%Marvin.Event{owner: owner}, fun \\ nil) do
    message_action(:answer_callback, owner, fun)
  end

  # TODO: move Marvin.Test.EventStore to adapter?
  defp message_action(action_name, owner, fun) do
    case Marvin.Test.EventStore.pop_action(owner) do
      {^action_name, message, opts} when is_function(fun, 2) ->
        fun.(message, opts)

      {^action_name, message, _opts} ->
        message

      action ->
        raise "expected #{action_name} action, got: #{inspect(action)}"
    end
  end
end
