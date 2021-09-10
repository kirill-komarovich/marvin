defmodule <%= @bot_namespace %>.Endpoint do
  use Marvin.Endpoint
<%= if @telegram do %>
  poller Marvin.Poller.Telegram
<% end %>
  matcher <%= @bot_namespace %>.Matcher
end
