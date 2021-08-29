defmodule Marvin.Matcher.MatcherableTest do
  use ExUnit.Case, async: true

  alias Marvin.Matcher.Matcherable
  alias Marvin.Event

  describe "Regex implementation" do
    @input %Event{text: "hello user!"}
    @matched ~r/^hello.*\!$/
    @matched_with_args ~r/^hello (?<name>[a-z]+)\!$/
    @unmatched ~r/^hello$/

    test "match/2 with matching input returns {:match, %{}}" do
      assert {:match, %{} = params} = Matcherable.match(@matched, @input)
      assert map_size(params) == 0
    end

    test "match/2 with matching input and named captures returns {:match, captures}" do
      assert {:match, %{"name" => "user"}} = Matcherable.match(@matched_with_args, @input)
    end

    test "match/2 with non matching input returns :nomatch" do
      assert :nomatch = Matcherable.match(@unmatched, @input)
    end
  end

  describe "BitString implementation" do
    @input %Event{text: "matched"}
    @matched "matched"
    @unmatched "unmatched"

    test "match/2 with matching input returns {:match, %{}}" do
      assert {:match, %{} = params} = Matcherable.match(@matched, @input)
      assert map_size(params) == 0
    end

    test "match/2 with non matching input returns :nomatch" do
      assert :nomatch = Matcherable.match(@unmatched, @input)
    end
  end

  describe "BubbleMatch implementation" do
    import BubbleMatch.Sigil

    @input %Event{text: "hello user!"}
    @input_without_params %Event{text: "hello!"}
    @matched ~m"hello"
    @matched_with_args ~m"hello [0-1=name]"
    @unmatched ~m"[person]"

    test "match/2 with matching input returns {:match, %{}}" do
      assert {:match, %{} = params} = Matcherable.match(@matched, @input)
      assert map_size(params) == 0
    end

    test "match/2 with matching input and named captures returns {:match, captures}" do
      assert {:match, %{"name" => ["user"]}} = Matcherable.match(@matched_with_args, @input)
    end

    test "match/2 with matching input and without params returns {:match, %{}}" do
      assert {:match, %{} = params} = Matcherable.match(@matched_with_args, @input_without_params)
      assert map_size(params) == 0
    end

    test "match/2 with named captures and joiner returns :match with joined captures" do
      assert {:match, %{"name" => "user"}} =
               Matcherable.match(@matched_with_args, @input, join: "")
    end

    test "match/2 with non matching input returns :nomatch" do
      assert :nomatch = Matcherable.match(@unmatched, @input)
    end
  end
end
