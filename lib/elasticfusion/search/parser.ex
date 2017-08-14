defmodule Elasticfusion.Search.Parser do
  import Elasticfusion.Search.Lexer

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

  def query(input, keyword_field, queryable_fields, field_transform) do
    {parsed, _final_state} =
      input
      |> initialize(keyword_field, queryable_fields, field_transform)
      |> disjunction()

    parsed
  end

  def disjunction(state) do
    {left, state} = conjunction(state)

    case disjunction_clauses([left], state) do
      {[single_clause], state} ->
        {single_clause, state}
      {clauses, state} ->
        {%{bool: %{should: clauses}}, state}
    end
  end
  def disjunction_clauses(left_clauses, state) do
    case match_or(state) do
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
        {%{bool: %{must: clauses}}, state}
    end
  end
  def conjunction_clauses(left_clauses, state) do
    case match_and(state) do
      {nil, state} ->
        {left_clauses, state}
      {_connective, state} ->
        {right_clause, state} = boolean_clause(state)
        conjunction_clauses(left_clauses ++ [right_clause], state)
    end
  end

  def boolean_clause(state) do
    {negation, state} = match_not(state)

    if negation do
      case boolean_clause(state) do
        {%{bool: %{must: conj_clauses}}, state} ->
          {%{bool: %{must_not: List.wrap(conj_clauses)}}, state}
        {%{bool: %{must_not: [clause]}}, state} ->
          {clause, state}
        {%{bool: %{must_not: clauses}}, state} ->
          {%{bool: %{must: List.wrap(clauses)}}, state}
        {expression, state} ->
          {%{bool: %{must_not: List.wrap(expression)}}, state}
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

  def field_query(%{field_transform: field_transform} = state) do
    case match_field(state) do
      {field, state} when not is_nil(field) ->
        {qualifier, state} = match_field_qualifier(state)
        {query, state} = safe_sting(state)

        {field_transform.(field, qualifier, query), state}
      {nil, state} ->
        {nil, state}
    end
  end

  def term(%{keyword_field: keyword_field} = state) do
    {term, state} = case quoted_string(state) do
      {s, _} = quoted_string when not is_nil(s) -> quoted_string
      _not_quoted_string -> string_with_balanced_parantheses(state)
    end

    {%{term: %{keyword_field => String.downcase(term)}}, state}
  end
end
