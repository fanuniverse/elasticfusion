defmodule Elasticfusion.Search.Parser do
  alias Elasticfusion.Search.Lexer
  import Elasticfusion.Search.Lexer, only: [
    match: 2, match_field: 1, match_field_qualifier: 1,
    left_parentheses: 1, right_parentheses: 2,
    safe_sting: 1, string_with_balanced_parantheses: 1, quoted_string: 1]

  # query                    = disjunction
  #                          ;
  # disjunction              = conjunction , { ( "OR" | "|" ) , conjunction }
  #                          ;
  # conjunction              = boolean clause , { ( "AND" | "," ) , boolean clause }
  #                          ;
  # boolean clause           = ( "NOT" | "-" ) , boolean clause
  #                          | clause
  #                          ;
  # clause                   = parenthesized expression
  #                          | field query
  #                          | term
  #                          ;
  # parenthesized expression = "(" , disjunction , ")"
  #                          ;
  # field query              = field , ":" , [ field qualifier ] , safe string
  #                          ;
  # term                     = quoted string
  #                          | string with balanced parentheses
  #                          ;

  def query(input, queryable_fields \\ []) do
    {parsed, _final_state} =
      input
      |> Lexer.initialize(queryable_fields)
      |> disjunction

    parsed
  end

  def disjunction(state) do
    {left, state} = conjunction(state)

    case disjunction_clauses([left], state) do
      {[single_clause], state} ->
        {single_clause, state}
      {clauses, state} ->
        {{:or, clauses}, state}
    end
  end
  def disjunction_clauses(left_clauses, state) do
    case match(state, :or) do
      {nil, state} ->
        {left_clauses, state}
      {_connective, state} ->
        {right_clause, state} = conjunction(state)
        disjunction_clauses(left_clauses ++ [right_clause], state)
    end
  end

  def conjunction(state) do
    {left, state} = boolean_clause(state)

    case conjunction_clauses([left], state) do
      {[single_clause], state} ->
        {single_clause, state}
      {clauses, state} ->
        {{:and, clauses}, state}
    end
  end
  def conjunction_clauses(left_clauses, state) do
    case match(state, :and) do
      {nil, state} ->
        {left_clauses, state}
      {_connective, state} ->
        {right_clause, state} = boolean_clause(state)
        conjunction_clauses(left_clauses ++ [right_clause], state)
    end
  end

  def boolean_clause(state) do
    {negation, state} = match(state, :not)

    if negation do
      {body, state} = boolean_clause(state)

      case body do
        {:not, expression} -> {expression, state}
        expression -> {{:not, expression}, state}
      end
    else
      clause(state)
    end
  end

  def clause(state) do
    case parenthesized_expression(state) do
      {clause, state} when not is_nil(clause) -> {clause, state}
      _not_parenthesized_expression ->
        case field_query(state) do
          {clause, state} when not is_nil(clause) -> {clause, state}
          _not_field_query ->
            term(state)
        end
    end
  end

  def parenthesized_expression(state) do
    case left_parentheses(state) do
      {count, state} when not is_nil(count) ->
        {body, state} = disjunction(state)

        case right_parentheses(state, count) do
          {count, state} when not is_nil(count) -> {body, state}
          _ ->
            raise Elasticfusion.Search.ImbalancedParenthesesError
        end
      _ ->
        {nil, state}
    end
  end

  def field_query(state) do
    {field, state} = match_field(state)

    if field do
      {qualifier, state} = match_field_qualifier(state)
      {query, state} = safe_sting(state)

      {{:field_query, field, qualifier, query}, state}
    else
      {nil, state}
    end
  end

  def term(state) do
    {term, state} = case quoted_string(state) do
      {s, _} = quoted_string when not is_nil(s) -> quoted_string
      _not_quoted_string -> string_with_balanced_parantheses(state)
    end

    {String.downcase(term), state}
  end
end
