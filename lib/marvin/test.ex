defmodule Marvin.Test do
  import ExUnit.Assertions

  def event do
    Marvin.Test.Adapter.event(%Marvin.Event{})
  end

  def from(attrs) do
    Marvin.Test.Adapter.from(attrs)
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
    |> Marvin.Test.Adapter.event(message, from)
    |> endpoint.call(endpoint.init([]))
  end

  @failure_message "expected a message to be sent, but nothing happened"

  def sent_message(fun \\ nil, timeout \\ 0) do
    event = assert_receive(_event, timeout, @failure_message)

    message_action(event, :send_message, fun)
  end

  @failure_message "expected a message to be edited, but nothing happened"

  def edited_message(fun \\ nil, timeout \\ 0) do
    event = assert_receive(_event, timeout, @failure_message)

    message_action(event, :edit_message, fun)
  end

  @failure_message "expected a callback to be answered, but nothing happened"

  def answered_callback(fun \\ nil, timeout \\ 0) do
    event = assert_receive(_event, timeout, @failure_message)

    message_action(event, :answer_callback, fun)
  end

  defp message_action(event, action_name, fun) do
    case event do
      {^action_name, message, opts} when is_function(fun, 2) ->
        fun.(message, opts)

      {^action_name, message, _opts} ->
        message

      action ->
        raise "expected #{action_name} action, got: #{inspect(action)}"
    end
  end
end
