defmodule ExpegTest do
  use ExUnit.Case

  def start_with_a_character(input, char, index) do
    case String.starts_with?(input, char) do
      true ->
        Expeg.consume(char, input, index)
      _ ->
        {:fail, index}
    end
  end

  def start_with_1(input, index) do
    start_with_a_character(input, "1", index)
  end

  def start_with_12(input, index) do
    start_with_a_character(input, "12", index)
  end

  def start_with_a(input, index) do
    start_with_a_character(input, "a", index)
  end

  def followed_by_a_2(input, index) do
    start_with_a_character(input, "2", index)
  end

  def followed_by_a_a(input, index) do
    start_with_a_character(input, "a", index)
  end

  test "can consume strings" do
    assert {"1234", "abcd", 4} == Expeg.string("1234").("1234abcd", 0)
    assert {:fail, 0} == Expeg.string("1234").("abcd1234", 0)
  end

  test "can consume with character classes" do
    assert {"1", "234abcd", 1} == Expeg.charclass("[1-3]").("1234abcd", 0)
    assert {:fail, 0} == Expeg.charclass("[A-Z]").("1234abcd", 0)
    assert {:fail, 0} == Expeg.charclass("[A-Z]").("", 0)
  end

  test "can consume anything" do
    assert {"1", "234abcd", 1} == Expeg.anything.("1234abcd", 0)
    assert {:fail, 0} == Expeg.anything.("", 0)
  end

  test "can consume optionnal expression" do
    assert {"1", "234abcd", 1} == Expeg.optionnal(&start_with_1/2).("1234abcd", 0)
    assert {[], "abcd1234", 0} == Expeg.optionnal(&start_with_1/2).("abcd1234", 0)
  end

  test "can consume an ordered choice between alternatives" do
    assert {"1", "234abcd", 1} == Expeg.choose([&start_with_1/2, &start_with_a/2]).("1234abcd", 0)
    assert {"a", "bcd1234", 1} == Expeg.choose([&start_with_1/2, &start_with_a/2]).("abcd1234", 0)
    assert {:fail, 0} == Expeg.choose([&start_with_1/2, &start_with_a/2]).("zzz", 0)
  end

  test "can consume a sequence of terminal and non terminals" do
    assert {["1", "2", "2"], "34abcd", 3} == Expeg.sequence([&start_with_1/2, &followed_by_a_2/2, &followed_by_a_2/2]).("12234abcd", 0)
    assert {["1", "2"], "34abcd", 2} == Expeg.sequence([&start_with_1/2, &followed_by_a_2/2]).("1234abcd", 0)
    assert {:fail, 1} == Expeg.sequence([&start_with_1/2, &followed_by_a_a/2]).("1234abcd", 0)
    assert {:fail, 0} == Expeg.sequence([&start_with_1/2, &followed_by_a_2/2]).("abcd1234", 0)
  end

  test "can consume a greedy repetition with at least one match" do
    assert {"1111", "abcd", 4} == Expeg.one_or_more(&start_with_1/2).("1111abcd", 0)
    assert {"1212", "abcd", 4} == Expeg.one_or_more(&start_with_12/2).("1212abcd", 0)
    assert {:fail, 0} == Expeg.one_or_more(&start_with_12/2).("abcd1212", 0)
  end

  test "can consume optional greedy repetition (any number of matches, including none)" do
    assert {"1111", "abcd", 4} == Expeg.zero_or_more(&start_with_1/2).("1111abcd", 0)
    assert {"1212", "abcd", 4} == Expeg.zero_or_more(&start_with_12/2).("1212abcd", 0)
    assert {[], "abcd1212", 0} == Expeg.zero_or_more(&start_with_12/2).("abcd1212", 0)
  end

  test "can make positive lookahead" do
    assert {[], "1234abcd", 0} == Expeg.assert(&start_with_1/2).("1234abcd", 0)
    assert {:fail, 0} == Expeg.assert(&start_with_1/2).("abcd1234", 0)
  end

  test "can make negative lookahead" do
    assert {[], "abcd1234", 0} == Expeg.not(&start_with_1/2).("abcd1234", 0)
    assert {:fail, 0} == Expeg.not(&start_with_1/2).("1234abcd", 0)
  end

  test "can tag the parse result" do
    assert {{:ones, "1"}, "234", 1} == Expeg.tag(:ones, &start_with_1/2).("1234", 0)
    assert {:fail, 0} == Expeg.tag(:ones, &start_with_1/2).("abcd1234", 0)
  end
end
