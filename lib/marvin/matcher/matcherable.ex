defprotocol Marvin.Matcher.Matcherable do
  @spec match(pattern :: term, event :: Marvin.Event.t(), opts :: keyword()) ::
          {:match, map()} | :nomatch
  def match(pattern, event, opts \\ [])
end

defimpl Marvin.Matcher.Matcherable, for: Regex do
  def match(pattern, %Marvin.Event{text: text}, _opts \\ []) do
    case Regex.match?(pattern, text) do
      true -> {:matched, process_params(pattern, text)}
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
  def match(pattern, %Marvin.Event{text: text}, _opts \\ []) do
    case BubbleMatch.match(pattern, text) do
      {:match, params} -> {:match, process_params(params)}
      :nomatch -> :nomatch
    end
  end

  defp process_params(params) when map_size(params) == 0, do: %{}

  defp process_params(params) when is_map(params) do
    Map.new(params, fn {key, values} ->
      {key, Enum.map(values, fn %BubbleMatch.Token{raw: value} -> value end)}
    end)
  end
end
