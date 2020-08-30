defmodule MarvinTest do
  use ExUnit.Case
  doctest Marvin

  test "greets the world" do
    assert Marvin.hello() == :world
  end
end
