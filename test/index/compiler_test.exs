defmodule Elasticfusion.Index.CompilerTest do
  use ExUnit.Case

  defmodule CompilerTestIndex do
    use Elasticfusion.Index

    index_name "compiler_test_index"
    document_type "compiler_test_type"
    index_settings %{number_of_shards: 1}

    mapping %{
      "tags" => %{type: :keyword},
      "stars" => %{type: :integer},
      "date" => %{type: :date}
    }

    serialize &(%{"tags" => &1.tags, "stars" => &1.stars, "date" => &1.date})

    queryable_fields ~w(date stars)

    keyword_field "tags"
  end

  test "compiles index_name/0, document_type/0, index_settings/0" do
    assert CompilerTestIndex.index_name() == "compiler_test_index"
    assert CompilerTestIndex.document_type() == "compiler_test_type"
    assert CompilerTestIndex.index_settings() == %{number_of_shards: 1}
  end

  test "compiles queryable_fields/0" do
    assert CompilerTestIndex.queryable_fields() == ~w(date stars)
  end

  test "compiles serialize/1" do
    assert CompilerTestIndex.serialize(
      %{tags: "peridot", stars: 5, date: "feb 2017"}) ==
      %{"tags" => "peridot", "stars" => 5, "date" => "feb 2017"}
  end

  test "defines transform/3 clauses for queryable_fields" do
    import Elasticfusion.Utils, only: [parse_nl_date: 1]

    assert CompilerTestIndex.transform("date", "earlier than", "2 months ago") ==
      %{range: %{"date" => %{lt: parse_nl_date("2 months ago")}}}

    assert CompilerTestIndex.transform("date", "later than", "2 months ago") ==
      %{range: %{"date" => %{gt: parse_nl_date("2 months ago")}}}

    assert CompilerTestIndex.transform("date", nil, "2 months ago") ==
      %{term: %{"date" => parse_nl_date("2 months ago")}}

    assert CompilerTestIndex.transform("stars", "less than", "10") ==
      %{range: %{"stars" => %{lt: "10"}}}

    assert CompilerTestIndex.transform("stars", "more than", "10") ==
      %{range: %{"stars" => %{gt: "10"}}}

    assert CompilerTestIndex.transform("stars", nil, "10") ==
      %{term: %{"stars" => "10"}}
  end
end
