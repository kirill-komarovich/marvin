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
  def match(pattern, event, opts \\ [])
end

defimpl Marvin.Matcher.Matcherable, for: Regex do
  def match(pattern, %Marvin.Event{text: text}, _opts \\ []) do
    case Regex.match?(pattern, text) do
      true -> {:match, process_params(pattern, text)}
      false -> :nomatch
    end
  end

  defp process_params(pattern, text) do
    case Regex.named_captures(pattern, text) do
      captures when is_map(captures) -> captures
      nil -> %{}
    end
  end
end

defimpl Marvin.Matcher.Matcherable, for: BitString do
  def match(pattern, %Marvin.Event{text: text}, _opts \\ []) do
    case text == pattern do
      true -> {:match, %{}}
      false -> :nomatch
    end
  end
end

defimpl Marvin.Matcher.Matcherable, for: BubbleMatch do
  def match(pattern, %Marvin.Event{text: text}, opts \\ []) do
    case BubbleMatch.match(pattern, text) do
      {:match, params} -> {:match, process_params(params, opts)}
      :nomatch -> :nomatch
    end
  end

  defp process_params(params, _opts) when map_size(params) == 0, do: %{}

  defp process_params(params, opts) when is_map(params) do
    joiner = Keyword.get(opts, :join, nil)

    Map.new(params, fn {key, values} ->
      values = Enum.map(values, fn %BubbleMatch.Token{raw: value} -> value end)
      values = if joiner != nil, do: Enum.join(values, joiner), else: values

      {key, values}
    end)
  end
end
