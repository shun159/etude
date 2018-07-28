defmodule EtudeTest do
  use ExUnit.Case
  doctest Etude

  test "greets the world" do
    assert Etude.hello() == :world
  end
end
