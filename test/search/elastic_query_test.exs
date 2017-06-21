defmodule Elasticfusion.Search.ElasticQueryTest do
  use ExUnit.Case

  import Elasticfusion.Search.ElasticQuery

  test "term" do
    assert build("peridot", :tags) ==
      %{term: %{tags: "peridot"}}
  end

  test "negated term" do
    assert build({:not, "peridot"}, :tags) ==
      %{bool: %{must_not: [%{term: %{tags: "peridot"}}]}}
  end

  test "conjunction" do
    assert build({:and, "gem", {:and, "peridot", "lapis lazuli"}}, :tags) ==
      %{bool: %{must: [
        %{term: %{tags: "gem"}},
        %{term: %{tags: "peridot"}},
        %{term: %{tags: "lapis lazuli"}}
      ]}}
  end

  test "negated conjunction" do
    assert build({:not,
                   {:and, "gem", {:and, "peridot", "lapis lazuli"}}}, :tags) ==
      %{bool: %{must_not: [
        %{term: %{tags: "gem"}},
        %{term: %{tags: "peridot"}},
        %{term: %{tags: "lapis lazuli"}}
      ]}}
  end

  test "disjunction" do
    assert build({:or, "gem", {:or, "peridot", "lapis lazuli"}}, :tags) ==
      %{bool: %{should: [
        %{term: %{tags: "gem"}},
        %{term: %{tags: "peridot"}},
        %{term: %{tags: "lapis lazuli"}}
      ]}}
  end

  test "negated disjunction" do
    assert build({:not,
                   {:or, "gem", {:or, "peridot", "lapis lazuli"}}}, :tags) ==
      %{bool: %{must_not: [
        %{bool: %{should: [
          %{term: %{tags: "gem"}},
          %{term: %{tags: "peridot"}},
          %{term: %{tags: "lapis lazuli"}}
        ]}}
      ]}}
  end

  test "complex boolean expression" do
    assert build(
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
        "too much?"}}, :tags) ==
      %{bool: %{must: [
        %{bool: %{should: [
          %{term: %{tags: "ruby"}},
          %{term: %{tags: "sapphire"}},
          %{bool: %{must: [
            %{term: %{tags: "pearl"}},
            %{term: %{tags: "amethyst"}}
          ]}},
          %{term: %{tags: "garnet"}}
        ]}},
        %{bool: %{should: [
          %{bool: %{must_not: [%{bool: %{should: [
            %{term: %{tags: "peridot"}},
            %{term: %{tags: "lapis"}},
            %{term: %{tags: "lazuli"}}
          ]}}]}},
          %{term: %{tags: "steven"}},
          %{bool: %{must_not: [%{term: %{tags: "gem"}}]}},
          %{term: %{tags: "diamond"}}
        ]}},
        %{term: %{tags: "too much?"}}
      ]}}
  end
end
