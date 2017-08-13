defmodule Elasticfusion.PeekTest do
  use ExUnit.Case

  import Elasticfusion.IndexAPI
  alias Elasticfusion.Document
  alias Elasticfusion.Search.Builder
  alias Elasticfusion.Peek

  defmodule Record do
    defstruct [:id, :stars, :date]
  end

  defmodule PeekTestIndex do
    use Elasticfusion.Index

    index_name "peek_test_index"
    document_type "peek_test_type"
    index_settings %{number_of_shards: 1}

    mapping %{
      "id" => %{type: :integer},
      "stars" => %{type: :integer},
      "date" => %{type: :date}
    }

    serialize &(%{"id" => &1.id, "stars" => &1.stars, "date" => &1.date})

    queryable_fields ~w(stars date)
  end

  setup do
    delete_index(PeekTestIndex)
    :ok = create_index(PeekTestIndex)
  end

  test "next_id/3" do
    r1 = indexed(%Record{id: 1, stars: 34, date: ~N[2017-02-01 16:20:00]})
    r2 = indexed(%Record{id: 2, stars: 30, date: ~N[2017-02-02 16:20:00]})
    r3 = indexed(%Record{id: 3, stars: 30, date: ~N[2017-02-03 16:20:00]})
    _r4 = indexed(%Record{id: 4, stars: 28, date: ~N[2017-02-03 16:20:01]})

    query =
      %{query: %{match_all: %{}}}
      |> Builder.add_sort("date", :asc)

    assert Peek.next_id(r1, query, PeekTestIndex) == {:ok, "2"}
    assert Peek.next_id(r2, query, PeekTestIndex) == {:ok, "3"}
    assert Peek.next_id(r3, query, PeekTestIndex) == {:ok, "4"}

    # using `id` as a tiebreaker for non-unique field
    query =
      %{query: %{match_all: %{}}}
      |> Builder.add_sort("stars", :desc)
      |> Builder.add_sort("id", :asc)

    assert Peek.next_id(r1, query, PeekTestIndex) == {:ok, "2"}
    assert Peek.next_id(r2, query, PeekTestIndex) == {:ok, "3"}
    assert Peek.next_id(r3, query, PeekTestIndex) == {:ok, "4"}
  end

  test "previous_id/3" do
    _r1 = indexed(%Record{id: 1, stars: 34, date: ~N[2017-02-01 16:20:00]})
    r2 = indexed(%Record{id: 2, stars: 30, date: ~N[2017-02-02 16:20:00]})
    r3 = indexed(%Record{id: 3, stars: 30, date: ~N[2017-02-03 16:20:00]})
    r4 = indexed(%Record{id: 4, stars: 28, date: ~N[2017-02-03 16:20:01]})

    query =
      %{query: %{match_all: %{}}}
      |> Builder.add_sort("date", :asc)

    assert Peek.previous_id(r4, query, PeekTestIndex) == {:ok, "3"}
    assert Peek.previous_id(r3, query, PeekTestIndex) == {:ok, "2"}
    assert Peek.previous_id(r2, query, PeekTestIndex) == {:ok, "1"}

    # using `id` as a tiebreaker for non-unique field
    query =
      %{query: %{match_all: %{}}}
      |> Builder.add_sort("stars", :desc)
      |> Builder.add_sort("id", :asc)

    assert Peek.previous_id(r4, query, PeekTestIndex) == {:ok, "3"}
    assert Peek.previous_id(r3, query, PeekTestIndex) == {:ok, "2"}
    assert Peek.previous_id(r2, query, PeekTestIndex) == {:ok, "1"}
  end

  def indexed(%Record{} = record) do
    :ok = Document.index(record, PeekTestIndex)
    Elastix.Index.refresh("localhost:9200", PeekTestIndex.index_name())

    record
  end
end
