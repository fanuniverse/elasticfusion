defmodule Elasticfusion.MoreLikeThisTest do
  use ExUnit.Case

  alias Elasticfusion.Search
  alias Elasticfusion.Search.Builder

  defmodule MoreLikeThisTestIndex do
    use Elasticfusion.Index

    index_name "more_like_this_test_index"
    document_type "more_like_this_test_type"
    index_settings %{number_of_shards: 1}

    mapping %{
      id: %{type: :integer},
      tags: %{type: :keyword}
    }

    serialize &(%{id: &1.id, tags: &1.tags})

    keyword_field :tags
  end

  alias MoreLikeThisTestIndex, as: Index

  setup_all do
    import Elasticfusion.IndexAPI

    delete_index(Index)
    :ok = create_index(Index)

    index [%{id: 1, tags: ~w(amethyst peridot pearl sapphire ruby)},
           %{id: 2, tags: ~w(amethyst peridot pearl)},
           %{id: 3, tags: ~w(amethyst pearl)},
           %{id: 4, tags: ~w(amethyst peridot)},
           %{id: 5, tags: ~w(sapphire ruby)}]

    :ok
  end

  describe "more like this" do
    test "with a sort" do
      assert Builder.more_like_this(1, Index)
        |> Builder.add_sort(:id, :asc)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["2", "3", "4", "5"], 4}

      assert Builder.more_like_this(1, Index)
        |> Builder.add_sort(:id, :desc)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["5", "4", "3", "2",], 4}
    end

    test "with a filter clause" do
      assert Builder.more_like_this(1, Index)
        |> Builder.add_filter_clause(%{bool:
          %{must_not: %{term: %{tags: "pearl"}}}})
        |> Builder.add_sort(:id, :desc)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["5", "4"], 2}
    end

    test "paginated" do
      assert Builder.more_like_this(1, Index)
        |> Builder.add_sort(:id, :asc)
        |> Builder.paginate(1, 2)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["2", "3"], 4}

      assert Builder.more_like_this(1, Index)
        |> Builder.add_sort(:id, :asc)
        |> Builder.paginate(2, 2)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["4", "5"], 4}
    end

    test "with a custom minimum_should_match" do
      assert Builder.more_like_this(1, Index, minimum_should_match: 2)
        |> Builder.add_sort(:id, :asc)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["2", "3", "4", "5"], 4}

      assert Builder.more_like_this(1, Index, minimum_should_match: 3)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, ["2"], 1}

      assert Builder.more_like_this(1, Index, minimum_should_match: 4)
        |> Search.find_ids(MoreLikeThisTestIndex)
        == {:ok, [], 0}
    end
  end

  def index(records) do
    for r <- records, do:
      :ok = Elasticfusion.Document.index(r, MoreLikeThisTestIndex)

    Elastix.Index.refresh("localhost:9200", MoreLikeThisTestIndex.index_name())
  end
end
