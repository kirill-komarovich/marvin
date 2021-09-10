defmodule <%= @bot_namespace %>.Matcher do
  use <%= @bot_namespace %>, :matcher

  handle ~m"hello", <%= @bot_namespace %>.HelloHandler
  handle ~r/*/, <%= @bot_namespace %>.UnknownHandler
end
