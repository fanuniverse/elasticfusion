defmodule Elasticfusion.Index.CompilerTest do
  use ExUnit.Case

  defmodule CompilerTestIndex do
    use Elasticfusion.Index

    index_name "compiler_test_index"
    document_type "compiler_test_type"
    index_settings %{number_of_shards: 1}

    mapping %{
      tags: %{type: :keyword},
      stars: %{type: :integer},
      date: %{type: :date}
    }

    serialize &(%{tags: &1.tags, stars: &1.stars, date: &1.created_at})

    keyword_field :tags

    queryable_fields [date: "created at", stars: "stars"]

    def_transform "starred by", fn
      (_, value, _) ->
        %{term: %{stars: value}}
    end

    def_transform "found in", fn
      (_, "my favorites", %{name: username}) ->
        %{term: %{tags: "faved by #{username}"}}
    end
  end

  test "compiles index_name/0, document_type/0, index_settings/0" do
    assert CompilerTestIndex.index_name() == "compiler_test_index"
    assert CompilerTestIndex.document_type() == "compiler_test_type"
    assert CompilerTestIndex.index_settings() == %{number_of_shards: 1}
  end

  test "compiles queryable_fields/0 that includes transforms" do
    assert CompilerTestIndex.queryable_fields() ==
      ["created at", "stars", "found in", "starred by"]
  end

  test "compiles serialize/1" do
    assert CompilerTestIndex.serialize(
      %{tags: "peridot", stars: 5, created_at: "feb 2017"}) ==
      %{tags: "peridot", stars: 5, date: "feb 2017"}
  end

  test "defines transform/3 clauses for queryable_fields" do
    import Elasticfusion.Utils, only: [parse_nl_date: 1]
    import CompilerTestIndex, only: [transform: 4]

    assert transform("created at", "earlier than", "2 months ago", nil) ==
      %{range: %{date: %{lt: parse_nl_date("2 months ago")}}}

    assert transform("created at", "later than", "2 months ago", nil) ==
      %{range: %{date: %{gt: parse_nl_date("2 months ago")}}}

    assert transform("created at", nil, "2 months ago", nil) ==
      %{term: %{date: parse_nl_date("2 months ago")}}

    assert transform("stars", "less than", "10", nil) ==
      %{range: %{stars: %{lt: "10"}}}

    assert transform("stars", "more than", "10", nil) ==
      %{range: %{stars: %{gt: "10"}}}

    assert transform("stars", nil, "10", nil) ==
      %{term: %{stars: "10"}}
  end

  test "defines transform/3 clauses for custom transforms" do
    import CompilerTestIndex, only: [transform: 4]

    assert transform("starred by", nil, "5", nil) ==
      %{term: %{stars: "5"}}

    assert transform("found in", nil, "my favorites", %{name: "cool username"}) ==
      %{term: %{tags: "faved by cool username"}}
  end
end
