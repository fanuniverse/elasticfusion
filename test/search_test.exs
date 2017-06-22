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
    def index_name(),       do: "search_test_index"
    def document_type(),    do: "search_test_type"
    def settings(),         do: %{number_of_shards: 1}
    def mapping() do
      %{
        "tags" => %{type: :keyword},
        "stars" => %{type: :integer},
        "date" => %{type: :date}
      }
    end
    def keyword_field(),    do: "tags"
    def queryable_fields(), do: ["stars", "date"]
    def serialize(%Record{tags: tags, stars: stars, date: date}) do
      %{"tags" => tags, "stars" => stars, "date" => date}
    end
  end

  setup do
    delete_index(SearchTestIndex)
    :ok = create_index(SearchTestIndex)
  end

  test "searching by query" do
    indexed(%Record{id: 3,
      tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]})

    query = Builder.parse_search_string(
      "peridot, stars: 30, date: earlier than feb 4 2017", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["3"]}

    query = Builder.parse_search_string(
      "peridot, stars: 30, date: earlier than feb 2 2017", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, []}
  end

  test "queries are case-insensitive" do
    indexed(%Record{id: 5,
      tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]})

    query = Builder.parse_search_string(
      "Peridot AND Lapis Lazuli", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["5"]}

    query = Builder.parse_search_string(
      "peRIdOt OR laPiS laZULI", SearchTestIndex)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["5"]}
  end

  test "manually built queries" do
    indexed(%Record{id: 7,
      tags: ["peridot", "lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]})
    indexed(%Record{id: 8,
      tags: ["peridot", "lapis lazuli", "ruby"], stars: 40, date: ~N[2017-02-03 16:20:00]})

    query =
      %{}
      |> Builder.add_filter_clause(%{range: %{stars: %{lt: 50}}})
      |> Builder.add_query_clause(%{term: %{"tags" => "peridot"}})
      |> Builder.add_query_clause(%{term: %{"tags" => "lapis lazuli"}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["7", "8"]}

    query =
      Builder.add_sort(query, :stars, :desc)

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["8", "7"]}

    query =
      Builder.add_filter_clause(query, %{term: %{"tags" => "ruby"}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["8"]}
  end

  test "combining queries with manual filters" do
    indexed(%Record{id: 9,
      tags: ["lapis lazuli"], stars: 12, date: ~N[2017-02-03 16:20:00]})
    indexed(%Record{id: 19,
      tags: ["lapis lazuli"], stars: 30, date: ~N[2017-02-03 16:20:00]})

    query =
      "lapis lazuli, date: earlier than 2 days ago"
      |> Builder.parse_search_string(SearchTestIndex)
      |> Builder.add_filter_clause(%{range: %{stars: %{gt: 10}}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["9", "19"]}

    query =
      Builder.add_filter_clause(query, %{range: %{stars: %{lt: 20}}})

    assert Search.find_ids(query, SearchTestIndex) == {:ok, ["9"]}
  end

  def indexed(%Record{} = record) do
    :ok = Document.index(record, SearchTestIndex)
    Elastix.Index.refresh("localhost:9200", SearchTestIndex.index_name())

    record
  end
end
