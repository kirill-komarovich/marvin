defmodule Marvin.Matcher.Parser do
  import NimbleParsec

  escaped =
    ignore(ascii_char([?\\]))
    |> ascii_string([], max: 1)

  term =
    choice([
      escaped,
      utf8_string([not: ?\\, not: ?*, not: ?<], min: 1)
    ])
    |> repeat_while({:non_special, []})
    |> reduce({Enum, :join, []})

  argument =
    ignore(string("<"))
    |> concat(utf8_string([not: ?>, not: ?:], min: 1))
    |> ignore(string(">"))
    |> unwrap_and_tag(:arg)

  pattern =
    choice([
      string("*") |> replace(:skip),
      argument,
      term
    ])
    |> repeat_while({:non_end, []})

  defparsec(:pattern, pattern)

  defp non_special(<<?*, _::binary>>, context, _, _), do: {:halt, context}
  defp non_special(<<?<, _::binary>>, context, _, _), do: {:halt, context}
  defp non_special(_, context, _, _), do: {:cont, context}

  defp non_end("", context, _, _), do: {:halt, context}
  defp non_end(_, context, _, _), do: {:cont, context}
end
