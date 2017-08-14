defmodule Elasticfusion.Search.LexerTest do
  use ExUnit.Case

  alias Elasticfusion.Search.Lexer

  test "matches a token and consumes whitespace past it" do
    {match, state} = run(&Lexer.match_and(&1),
      "AND something else")
    assert "AND" == match
    assert %{input: "something else"} = state
  end

  test "matches safe strings" do
    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17")
    assert match == "safe string with - and _ and 20 17"
    assert %{input: ""} = state

    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17, irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert %{input: ", irrelevant part"} = state

    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17    | irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert %{input: "| irrelevant part"} = state

    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17 OR irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert %{input: "OR irrelevant part"} = state
  end

  test "matches strings with balanced parentheses" do
    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "(safe string) with - and _ (and) 20 17 and (balanced)")
    assert match == "(safe string) with - and _ (and) 20 17 and (balanced)"
    assert %{input: ""} = state

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "(safe string) with - and _    ")
    assert match == "(safe string) with - and _"
    assert %{input: ""} = state

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "(safe string) (balanced)) ")
    assert match == "(safe string) (balanced)"
    assert %{input: ") "} = state

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "safe string with - and _ and 20 17), irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert %{input: "), irrelevant part"} = state

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "safe string with - and _ and 20 17    OR irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert %{input: "OR irrelevant part"} = state
  end

  test "matches quoted strings" do
    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"this is a \"quoted\" string ) , AND OR ((( "})
    assert match == ~s{this is a "quoted" string ) , AND OR ((( }
    assert %{input: ""} = state

    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"this is a \"quoted\" string ) , AND OR ((( "irrelevant part})
    assert match == ~S{this is a "quoted" string ) , AND OR ((( }
    assert %{input: "irrelevant part"} = state

    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"\"beginning\" and ending with a \"quote\""   , irrelevant part})
    assert match == ~S{"beginning" and ending with a "quote"}
    assert %{input: ", irrelevant part"} = state

    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"one string" BUT WAIT "there's more"})
    assert match == ~S{one string}
    assert %{input: ~S{BUT WAIT "there's more"}} = state
  end

  test "matches parentheses" do
    {count, state} = run(&Lexer.left_parentheses/1,
      "( (   (    (     unrelated")
    assert count == 4
    assert %{input: "unrelated"} = state

    {count, state} = run(&Lexer.left_parentheses/1,
      " no parentheses")
    assert count == nil
    assert %{input: "no parentheses"} = state

    {count, state} = run(&Lexer.right_parentheses(&1, 3),
      ")    ) )) )) unrelated ))")
    assert count == 3
    assert %{input: ") )) unrelated ))"} = state

    {count, state} = run(&Lexer.right_parentheses(&1, 6),
      ")    ) )) )) unrelated ))")
    assert count == 6
    assert %{input: "unrelated ))"} = state

    {count, state} = run(&Lexer.right_parentheses(&1, 8),
      ")    ) )) )) unrelated ))")
    assert count == nil
    assert %{input: ")    ) )) )) unrelated ))"} = state

    {count, state} = run(&Lexer.right_parentheses(&1, 1),
      " no parentheses")
    assert count == nil
    assert %{input: "no parentheses"} = state
  end

  defp run(fun, input) when is_function(fun, 1) and is_binary(input) do
    input
    |> Lexer.initialize([])
    |> fun.()
  end
end
