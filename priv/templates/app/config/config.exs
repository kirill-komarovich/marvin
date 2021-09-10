import Config
<%= if @telegram do %>
config :nadia, token: "your-bot-token"
<% end %>
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:event_id]
