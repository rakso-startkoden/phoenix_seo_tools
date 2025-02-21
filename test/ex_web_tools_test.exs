defmodule ExWebToolsTest do
  use ExUnit.Case
  doctest ExWebTools

  test "greets the world" do
    assert ExWebTools.hello() == :world
  end
end
