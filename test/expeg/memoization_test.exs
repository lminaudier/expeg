defmodule Expeg.MemoizationTest do
  use ExUnit.Case

  setup do
    Expeg.Memoization.prepare(__MODULE__)
    :ok
  end

  test "can set then get values from the store" do
    Expeg.Memoization.set(0, {"parse", "result"})
    assert {"parse", "result"} == Expeg.Memoization.get(0)
  end
end
