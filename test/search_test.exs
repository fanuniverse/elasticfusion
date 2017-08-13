defmodule Elasticfusion.SearchTest do
  use ExUnit.Case

  import Elasticfusion.IndexAPI
  alias Elasticfusion.Document
  alias Elasticfusion.Search
  alias Elasticfusion.Search.Builder

  defmodule Record do
    defstruct [:id, :tags, :stars, :date]
  end

  defmodule SearchTestIndex do
    use Elasticfusion.Index

    index_name "search_test_index"
    document_type "search_test_type"
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

  setup do
    delete_index(SearchTestIndex)
    :ok = create_index(SearchTestIndex)
  end

  test "searching by query" do
    index %Record{id: 1,
      tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]}

    query = Builder.parse_search_string(
      "peridot, stars: 30, date: earlier than feb 4 2017", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["1"], 1}

    query = Builder.parse_search_string(
      "peridot, stars: 30, date: earlier than feb 2 2017", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, [], 0}
  end

  test "search results include the total number of records" do
    for id <- 2..5 do
      index %Record{id: id,
        tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]}
    end

    query =
      "peridot"
      |> Builder.parse_search_string(SearchTestIndex)
      |> Builder.paginate(1, 2)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["2", "3"], 4}
  end

  test "queries are case-insensitive" do
    index %Record{id: 6,
      tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]}

    query = Builder.parse_search_string(
      "Peridot AND Lapis Lazuli", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["6"], 1}

    query = Builder.parse_search_string(
      "peRIdOt OR laPiS laZULI", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["6"], 1}
  end

  test "manually built queries" do
    index %Record{id: 7,
      tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]}
    index %Record{id: 8,
      tags: ["peridot", "lapis lazuli", "ruby"], stars: 40, date: ~N[2017-02-03 16:20:00]}

    query =
      %{}
      |> Builder.add_filter_clause(%{range: %{stars: %{lt: 50}}})
      |> Builder.add_query_clause(%{term: %{"tags" => "peridot"}})
      |> Builder.add_query_clause(%{term: %{"tags" => "lapis lazuli"}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["7", "8"], 2}

    query =
      Builder.add_sort(query, :stars, :desc)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["8", "7"], 2}

    query =
      Builder.add_filter_clause(query, %{term: %{"tags" => "ruby"}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["8"], 1}
  end

  test "combining queries with manual filters" do
    index %Record{id: 9,
      tags: ["lapis lazuli"], stars: 12, date: ~N[2017-02-03 16:20:00]}
    index %Record{id: 19,
      tags: ["lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]}

    query =
      "lapis lazuli, date: earlier than 2 days ago"
      |> Builder.parse_search_string(SearchTestIndex)
      |> Builder.add_filter_clause(%{range: %{stars: %{gt: 10}}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["9", "19"], 2}

    query =
      Builder.add_filter_clause(query, %{range: %{stars: %{lt: 20}}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["9"], 1}
  end

  def index(%Record{} = record) do
    :ok = Document.index(record, SearchTestIndex)
    Elastix.Index.refresh("localhost:9200", SearchTestIndex.index_name())

    record
  end
end
