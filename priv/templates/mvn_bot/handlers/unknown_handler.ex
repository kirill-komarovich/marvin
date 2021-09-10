defmodule <%= @bot_namespace %>.UnknownHandler do
  use <%= @bot_namespace %>, :handler

  def call(event, _opts) do
    send_message(event, "Unknown message", reply: true)
  end
end
