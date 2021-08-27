defmodule Marvin.Matcher.CompilerTest do
  use ExUnit.Case, async: true

  defmodule DummyMatcher do
    @handlers [
      {["strict"], StrictHandler, []},
      {["skip*"], SkipHandler, []},
    ]

    defmacro __before_compile__(env) do
      handlers = env.module |> Module.get_attribute(:handlers) |> Enum.reverse() |> Macro.escape()

      quote do
        @doc false
        def __handlers__, do: unquote(handlers)

        unquote(Marvin.Matcher.Compiler.compile(handlers))
      end
    end
  end

  test "compiles matcher for strict pattern" do
    string = "strict"

    assert {{StrictHandler, []}} = Parser.pattern(string)
  end
end
