defmodule Elasticfusion.Search.FlattenerTest do
  use ExUnit.Case
  doctest Elasticfusion.Search.Flattener

  import Elasticfusion.Search.Flattener

  test "flattens right-leaning tree" do
    assert flatten(
      {:and,
        "pearl",
        {:and,
          "ruby",
          {:and,
            "sapphire",
            {:not, "amethyst"}}}}) ==
      {:and, ["pearl", "ruby", "sapphire", {:not, "amethyst"}]}
  end

  test "flattens left-leaning tree" do
    assert flatten(
      {:and,
        {:and,
          {:and,
            "sapphire",
            {:not, "amethyst"}},
          "ruby"},
        "pearl"}) ==
      {:and, ["sapphire", {:not, "amethyst"}, "ruby", "pearl"]}
  end

  test "flattens sub-trees" do
    assert flatten(
      {:and,
        {:or,
          {:or, "ruby", "sapphire"},
          {:or,
            {:and, "pearl", "amethyst"},
            "garnet"}},
        {:and,
          {:or,
            {:or,
              {:not,
                {:or,
                  "peridot",
                  {:or, "lapis", "lazuli"}}},
              "steven"},
            {:or, {:not, "gem"}, "diamond"}},
        "too much?"}}) ==
    {:and, [
      {:or, [
        "ruby",
        "sapphire",
        {:and, ["pearl", "amethyst"]},
        "garnet"
      ]},
      {:or, [
        {:not,
          {:or, [
            "peridot", "lapis", "lazuli"
        ]}},
        "steven",
        {:not, "gem"},
        "diamond"
      ]},
      "too much?"
    ]}
  end
end
