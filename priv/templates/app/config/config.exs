import Config
<%= if @telegram do %>
config :ex_gram, token: "your-bot-token"
<% end %>
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:event_id]
