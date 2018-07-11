defmodule ChaoiseContextTest do
  use ExUnit.Case
  doctest ChaoiseContext

  test "greets the world" do
    assert ChaoiseContext.hello() == :world
  end
end
