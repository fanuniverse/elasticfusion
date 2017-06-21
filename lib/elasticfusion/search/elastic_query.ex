defmodule Elasticfusion.Search.ElasticQuery do
  @es_operators %{
    and: :must,
    or: :should
  }

  import Enum, only: [map: 2]
  import Elasticfusion.Search.Flattener
  import Elasticfusion.Search.ElasticValue

  @doc """
  Transforms an expression tree produced by
  `Elasticfusion.Search.Parser` into an Elasticsearch query.

  The `index` argument accepts a module implementing the
  `Elasticfusion.Index` behavior.
  """
  def build(expression, index) do
    transform(flatten(expression), index)
  end

  def transform({:not, {:and, children}}, index) do
    operands = map(children, &transform(&1, index))

    %{bool: %{must_not: operands}}
  end
  def transform({:not, expression}, index) do
    clause = [transform(expression, index)]

    %{bool: %{must_not: clause}}
  end
  def transform({op, children}, index) do
    operator = @es_operators[op]
    operands = map(children, &transform(&1, index))

    %{bool: %{operator => operands}}
  end
  def transform({:field_query, field, nil, value}, index) do
    es_value = es_value(value, field, index)

    %{term: %{field => es_value}}
  end
  def transform({:field_query, field, qualifier, value}, index) do
    es_value = es_value(value, field, index)

    %{range: %{field => %{qualifier =>  es_value}}}
  end
  def transform(keyword_term, index) do
    %{term: %{index.keyword_field() => keyword_term}}
  end
end
