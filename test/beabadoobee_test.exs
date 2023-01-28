defmodule BeabadoobeeTest do
  use ExUnit.Case
  doctest Beabadoobee

  test "greets the world" do
    assert Beabadoobee.hello() == :world
  end
end
