defmodule ExpegTest do
  use ExUnit.Case

  def start_with_a_character(input, char) do
    case String.starts_with?(input, char) do
      true ->
        Expeg.consume(char, input)
      _ ->
        :fail
    end
  end

  def start_with_1(input) do
    start_with_a_character(input, "1")
  end

  def start_with_12(input) do
    start_with_a_character(input, "12")
  end

  def start_with_a(input) do
    start_with_a_character(input, "a")
  end

  def followed_by_a_2(input) do
    start_with_a_character(input, "2")
  end

  def followed_by_a_a(input) do
    start_with_a_character(input, "a")
  end

  test "can consume strings" do
    assert {"1234", "abcd"} == Expeg.string("1234").("1234abcd")
    assert :fail == Expeg.string("1234").("abcd1234")
  end

  test "can consume with character classes" do
    assert {"1", "234abcd"} == Expeg.charclass("[1-3]").("1234abcd")
    assert :fail == Expeg.charclass("[A-Z]").("1234abcd")
    assert :fail == Expeg.charclass("[A-Z]").("")
  end

  test "can consume anything" do
    assert {"1", "234abcd"} == Expeg.anything.("1234abcd")
    assert :fail == Expeg.anything.("")
  end

  test "can consume optionnal expression" do
    assert {"1", "234abcd"} == Expeg.optionnal(&start_with_1/1).("1234abcd")
    assert {[], "abcd1234"} == Expeg.optionnal(&start_with_1/1).("abcd1234")
  end

  test "can consume an ordered choice between alternatives" do
    assert {"1", "234abcd"} == Expeg.choose([&start_with_1/1, &start_with_a/1]).("1234abcd")
    assert {"a", "bcd1234"} == Expeg.choose([&start_with_1/1, &start_with_a/1]).("abcd1234")
    assert :fail == Expeg.choose([&start_with_1/1, &start_with_a/1]).("zzz")
  end

  test "can consume a sequence of terminal and non terminals" do
    assert {["1", "2", "2"], "34abcd"} == Expeg.sequence([&start_with_1/1, &followed_by_a_2/1, &followed_by_a_2/1]).("12234abcd")
    assert {["1", "2"], "34abcd"} == Expeg.sequence([&start_with_1/1, &followed_by_a_2/1]).("1234abcd")
    assert :fail == Expeg.sequence([&start_with_1/1, &followed_by_a_a/1]).("1234abcd")
    assert :fail == Expeg.sequence([&start_with_1/1, &followed_by_a_2/1]).("abcd1234")
  end

  test "can consume a greedy repetition with at least one match" do
    assert {"1111", "abcd"} == Expeg.one_or_more(&start_with_1/1).("1111abcd")
    assert {"1212", "abcd"} == Expeg.one_or_more(&start_with_12/1).("1212abcd")
    assert :fail == Expeg.one_or_more(&start_with_12/1).("abcd1212")
  end

  test "can consume optional greedy repetition (any number of matches, including none)" do
    assert {"1111", "abcd"} == Expeg.zero_or_more(&start_with_1/1).("1111abcd")
    assert {"1212", "abcd"} == Expeg.zero_or_more(&start_with_12/1).("1212abcd")
    assert {[], "abcd1212"} == Expeg.zero_or_more(&start_with_12/1).("abcd1212")
  end

  test "can make positive lookahead" do
    assert {[], "1234abcd"} == Expeg.assert(&start_with_1/1).("1234abcd")
    assert :fail == Expeg.assert(&start_with_1/1).("abcd1234")
  end

  test "can make negative lookahead" do
    assert {[], "abcd1234"} == Expeg.not(&start_with_1/1).("abcd1234")
    assert :fail == Expeg.not(&start_with_1/1).("1234abcd")
  end

  test "can tag the parse result" do
    assert {{:ones, "1"}, "234"} == Expeg.tag(:ones, &start_with_1/1).("1234")
    assert :fail == Expeg.tag(:ones, &start_with_1/1).("abcd1234")
  end
end
