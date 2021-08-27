defmodule Marvin.Matcher.ParserTest do
  use ExUnit.Case, async: true

  alias Marvin.Matcher.Parser

  test "pattern/1 parses exact string" do
    string = "some string"

    assert {:ok, [^string], _, _, _, _} = Parser.pattern(string)
  end

  test "pattern/1 parses *" do
    assert {:ok, [:skip], _, _, _, _} = Parser.pattern("*")
  end

  test "pattern/1 parses argument wrapped in <>" do
    name = "arg_name"

    assert {:ok, [{:arg, ^name}], _, _, _, _} = Parser.pattern("<#{name}>")
  end

  test "pattern/1 parses string when used only > symbol" do
    string = "arg_name>"

    assert {:ok, [^string], _, _, _, _} = Parser.pattern(string)
  end

  test "pattern/1 parses exact string with *" do
    string = "some string"
    pattern = "#{string}*"

    assert {:ok, [^string, :skip], _, _, _, _} = Parser.pattern(pattern)
  end

  test "pattern/1 parses exact string with argument" do
    string = "some string"
    name = "arg_name"
    pattern = "#{string}<#{name}>"

    assert {:ok, [^string, {:arg, ^name}], _, _, _, _} = Parser.pattern(pattern)
  end

  test "pattern/1 parses exact string with argument and *" do
    string = "some string"
    name = "arg_name"
    pattern = "#{string}<#{name}>*"

    assert {:ok, [^string, {:arg, ^name}, :skip], _, _, _, _} = Parser.pattern(pattern)
  end

  test "pattern/1 parses with escaped *" do
    pattern = "some  string \\*postfix"
    string = "some  string *postfix"

    assert {:ok, [^string], _, _, _, _} = Parser.pattern(pattern)
  end

  test "pattern/1 parses with escaped <" do
    pattern = "some  string \\<arg>"
    string = "some  string <arg>"

    assert {:ok, [^string], _, _, _, _} = Parser.pattern(pattern)
  end
end
