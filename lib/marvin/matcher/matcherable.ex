defprotocol Marvin.Matcher.Matcherable do
  @moduledoc """
  Matcherable protocol used by `Marvin.Matcher` for matching message pattern with given input
  """

  @doc """
  Matches pattern with event text.
  With valid input returns `{:match, params}` tuple, with invalid - `:nomatch`

  ## Examples

    iex> #{__MODULE__}.match("hello", %Marvin.Event{text: "hello"})
    {:match, %{}}

    iex> #{__MODULE__}.match("hello", %Marvin.Event{text: "world"})
    :nomatch
  """
  @spec match(pattern :: term, event :: Marvin.Event.t(), opts :: keyword()) ::
          {:match, map()} | :nomatch
  def match(pattern, event, opts)
end

defimpl Marvin.Matcher.Matcherable, for: Regex do
  def match(pattern, %Marvin.Event{text: text}, _opts) do
    case Regex.match?(pattern, text) do
      true -> {:match, process_params(pattern, text)}
      false -> :nomatch
    end
  end

  defp process_params(pattern, text) do
    Regex.named_captures(pattern, text)
  end
end

defimpl Marvin.Matcher.Matcherable, for: BitString do
  def match(pattern, %Marvin.Event{text: text}, _opts) do
    case text == pattern do
      true -> {:match, %{}}
      false -> :nomatch
    end
  end
end
