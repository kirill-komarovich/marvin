defmodule Marvin.Event.From do
  @type t :: %__MODULE__{
          id: number(),
          first_name: String.t(),
          last_name: String.t(),
          username: String.t(),
          raw: term()
        }
  defstruct id: nil,
            username: nil,
            first_name: nil,
            last_name: nil,
            raw: nil
end
