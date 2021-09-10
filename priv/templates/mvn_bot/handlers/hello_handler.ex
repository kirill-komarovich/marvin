defmodule <%= @bot_namespace %>.HelloHandler do
  use <%= @bot_namespace %>, :handler

  def call(event, _opts) do
    send_message(event, "Hello!", reply: true)
  end
end
