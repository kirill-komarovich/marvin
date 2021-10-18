defmodule Marvin.Pipeline do
  @type opts :: term()

  @callback init(opts) :: opts
  @callback call(event :: Marvin.Event.t(), opts) :: Marvin.Event.t()
end
