defmodule <%= @bot_namespace %>.Endpoint do
  use Marvin.Endpoint, otp_app: :<%= @app_name %>
<%= if @telegram do %>
  poller Marvin.Telegram.Poller
<% end %>
  plug Marvin.Pipeline.Logger

  plug <%= @bot_namespace %>.Matcher
end
