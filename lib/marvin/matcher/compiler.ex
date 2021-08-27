defmodule Marvin.Matcher.Compiler do
  import NimbleParsec

  def compile(handlers) when is_list(handlers) do
    quote do
      import NimbleParsec

      combinators = Enum.map(unquote(handlers), fn {pattern, handler, opts} ->
        Matcher.Compiler.compile_combinator(pattern, handler, opts)
      end)

      defparsecp(:match_pattern, choice(combinators), debug: true)

      def do_match(binary) do
        {:ok, [turple], _, _, _, _} = match_pattern(binary)
        turple
      end

      defp non_text(data, context, _, _, text) do
        case data do
          ^text -> {:halt, context}
          <<^text, _::binary>> -> {:halt, context}
          _ -> {:cont, context}
        end
      end
    end
  end

  def compile_combinator([first | pattern], mod, opts) do
    build_combinator(empty(), first, pattern)
    |> eos()
    |> replace({mod, opts})
  end

  defp build_combinator(acc, text, [:skip]) when is_binary(text) do
    acc
    |> build_combinator(text, [])
    |> build_combinator(:skip, [])
  end

  defp build_combinator(acc, text, [:skip, next | pattern]) when is_binary(text) do
    acc
    |> build_combinator(text, [])
    |> ignore(
      repeat_while(
        utf8_char([]),
        {:non_text, [next]}
      )
    )
    |> build_combinator(next, pattern)
  end

  defp build_combinator(acc, text, []) when is_binary(text) do
    string(acc, text)
  end

  defp build_combinator(acc, text, [next | pattern]) when is_binary(text) do
    build_combinator(
      build_combinator(acc, text, []),
      next,
      pattern
    )
  end

  defp build_combinator(acc, :skip, []) do
    ignore(acc, utf8_string([], min: 1))
  end

  defp build_combinator(acc, :skip, [next | pattern]) do
    build_combinator(
      build_combinator(acc, :skip, []),
      next,
      pattern
    )
  end

  defp build_combinator(acc, {:arg, _}, []) do
    acc
  end

  defp build_combinator(acc, {:arg, _} = arg, [next | pattern]) do
    build_combinator(
      build_combinator(acc, arg, []),
      next,
      pattern
    )
  end
end
