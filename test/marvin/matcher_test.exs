defmodule Marvin.MatcherTest do
  use ExUnit.Case, async: true

  defmodule CustomMatcher do
    defimpl Marvin.Matcher.Matcherable, for: __MODULE__ do
      def match?(pattern, event) do
        assert pattern == CustomMatcher
        true
      end
    end
  end

  defmodule RegexHandler do
    use Marvin.Handler
  end

  defmodule StringHandler do
    use Marvin.Handler
  end

  defmodule CustomHandler do
    use Marvin.Handler
  end

  defmodule Matcher do
    use Marvin.Matcher

    handle ~r/test_regex/, RegexHandler
    handle "test_string", StringHandler
    handle CustomMatcher, CustomHandler
  end

  test "__handlers__/0 returns all registered handlers with patterns" do
    expected = [
      {~r/test_regex/, TestHandler},
      {"test_string", TestHandler},
      {CustomMatcher, TestHandler}
    ]

    assert Matcher.__handlers__() == expected
  end

  test "call/1 when triggers regex matcher" do
    assert false
  end

  test "call/1 when triggers string matcher" do
    assert false
  end

  test "call/1 when triggers custom matcher" do
    assert false
  end
end
