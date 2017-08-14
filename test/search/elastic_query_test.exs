defmodule Elasticfusion.Search.ElasticQueryTest do
  use ExUnit.Case

  import Elasticfusion.Search.ElasticQuery
  import Elasticfusion.Search.ElasticValue, only: [date: 1]

  defmodule TestIndex do
    use Elasticfusion.Index

    index_name "elastic_query_test_index"
    document_type "elastic_query_test_type"
    index_settings %{number_of_shards: 1}

    mapping %{
      "tags" => %{type: :keyword},
      "stars" => %{type: :integer},
      "date" => %{type: :date}
    }

    serialize &(%{"tags" => &1.tags, "stars" => &1.stars, "date" => &1.date})

    keyword_field "tags"
    queryable_fields ~w(stars date)
  end

  test "term" do
    assert build("peridot", TestIndex) ==
      %{term: %{"tags" => "peridot"}}
  end

  test "negated term" do
    assert build({:not, "peridot"}, TestIndex) ==
      %{bool: %{must_not: [%{term: %{"tags" => "peridot"}}]}}
  end

  test "conjunction" do
    assert build({:and, ["gem", "peridot", "lapis lazuli"]}, TestIndex) ==
      %{bool: %{must: [
        %{term: %{"tags" => "gem"}},
        %{term: %{"tags" => "peridot"}},
        %{term: %{"tags" => "lapis lazuli"}}
      ]}}
  end

  test "negated conjunction" do
    assert build({:not,
                   {:and, ["gem", "peridot", "lapis lazuli"]}}, TestIndex) ==
      %{bool: %{must_not: [
        %{term: %{"tags" => "gem"}},
        %{term: %{"tags" => "peridot"}},
        %{term: %{"tags" => "lapis lazuli"}}
      ]}}
  end

  test "disjunction" do
    assert build({:or, ["gem", "peridot", "lapis lazuli"]}, TestIndex) ==
      %{bool: %{should: [
        %{term: %{"tags" => "gem"}},
        %{term: %{"tags" => "peridot"}},
        %{term: %{"tags" => "lapis lazuli"}}
      ]}}
  end

  test "negated disjunction" do
    assert build({:not,
                   {:or, ["gem", "peridot", "lapis lazuli"]}}, TestIndex) ==
      %{bool: %{must_not: [
        %{bool: %{should: [
          %{term: %{"tags" => "gem"}},
          %{term: %{"tags" => "peridot"}},
          %{term: %{"tags" => "lapis lazuli"}}
        ]}}
      ]}}
  end

  test "complex boolean expression" do
    assert build(
      {:and,
        [{:or,
           ["ruby",
            "sapphire",
            {:and, ["pearl", "amethyst"]},
            "garnet"]},
         {:or,
           [{:not,
              {:or, ["peridot", "lapis", "lazuli"]}},
            "steven",
            {:not, "gem"},
            "diamond"]},
         "too much?"]}, TestIndex) ==
      %{bool: %{must: [
        %{bool: %{should: [
          %{term: %{"tags" => "ruby"}},
          %{term: %{"tags" => "sapphire"}},
          %{bool: %{must: [
            %{term: %{"tags" => "pearl"}},
            %{term: %{"tags" => "amethyst"}}
          ]}},
          %{term: %{"tags" => "garnet"}}
        ]}},
        %{bool: %{should: [
          %{bool: %{must_not: [%{bool: %{should: [
            %{term: %{"tags" => "peridot"}},
            %{term: %{"tags" => "lapis"}},
            %{term: %{"tags" => "lazuli"}}
          ]}}]}},
          %{term: %{"tags" => "steven"}},
          %{bool: %{must_not: [%{term: %{"tags" => "gem"}}]}},
          %{term: %{"tags" => "diamond"}}
        ]}},
        %{term: %{"tags" => "too much?"}}
      ]}}
  end

  test "range queries" do
    assert build(
      {:or,
        [{:field_query, "date", :lt, "feb 3 2017 16:20"},
         {:field_query, "stars", :gt, "50"}]}, TestIndex) ==
    %{bool: %{should: [
      %{range: %{"date" => %{lt: date("feb 3 2017 16:20")}}},
      %{range: %{"stars" => %{gt: "50"}}}
    ]}}
  end

  test "field queries" do
    assert build(
      {:or,
        [{:field_query, "date", nil, "feb 4 2017 16:20"},
         {:field_query, "stars", nil, "50"}]}, TestIndex) ==
      %{bool: %{should: [
        %{term: %{"date" => date("feb 4 2017 16:20")}},
        %{term: %{"stars" => "50"}}
      ]}}
  end
end
