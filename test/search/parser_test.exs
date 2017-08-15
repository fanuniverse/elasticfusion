defmodule Elasticfusion.Search.ParserTest do
  use ExUnit.Case

  import Elasticfusion.Search.Parser, only: [query: 4]

  def query(str, field),
    do: query(str, field, [], fn(_, _, _) -> nil end)

  test "simple terms" do
    assert query("peridot", "tags") ==
      %{term: %{"tags" => "peridot"}}

    assert query("NOT lapis lazuli", "tags") ==
      %{bool: %{must_not: [
        %{term: %{"tags" => "lapis lazuli"}}
      ]}}
  end

  test "redundant negation" do
    assert query("NOT NOT NOT NOT peridot", "tags") ==
      %{term: %{"tags" => "peridot"}}

    assert query("NOT NOT NOT NOT NOT peridot", "tags") ==
      %{bool: %{must_not: [
        %{term: %{"tags" => "peridot"}}
      ]}}
  end

  test "single conjunction and disjunction" do
    assert query("peridot, lapis lazuli", "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => "peridot"}},
        %{term: %{"tags" => "lapis lazuli"}}
      ]}}

    assert query("peridot | lapis lazuli", "tags") ==
      %{bool: %{should: [
        %{term: %{"tags" => "peridot"}},
        %{term: %{"tags" => "lapis lazuli"}}
      ]}}
  end

  test "operator precedence and associativity" do
    assert query("ruby, sapphire, pearl | sardonyx", "tags") ==
      %{bool: %{should: [
        %{bool: %{must: [
          %{term: %{"tags" => "ruby"}},
          %{term: %{"tags" => "sapphire"}},
          %{term: %{"tags" => "pearl"}}
        ]}},
        %{term: %{"tags" => "sardonyx"}}
      ]}}

    assert query("sardonyx | ruby, sapphire, pearl", "tags") ==
      %{bool: %{should: [
        %{term: %{"tags" => "sardonyx"}},
        %{bool: %{must: [
          %{term: %{"tags" => "ruby"}},
          %{term: %{"tags" => "sapphire"}},
          %{term: %{"tags" => "pearl"}}
        ]}}
      ]}}

    assert query("-ruby, -sapphire, -pearl | -sardonyx", "tags") ==
      %{bool: %{should: [
        %{bool: %{must: [
          %{bool: %{must_not: [%{term: %{"tags" => "ruby"}}]}},
          %{bool: %{must_not: [%{term: %{"tags" => "sapphire"}}]}},
          %{bool: %{must_not: [%{term: %{"tags" => "pearl"}}]}}
        ]}},
        %{bool: %{must_not: [%{term: %{"tags" => "sardonyx"}}]}}
      ]}}

    assert query("-sardonyx | -ruby, -sapphire, -pearl", "tags") ==
      %{bool: %{should: [
        %{bool: %{must_not: [%{term: %{"tags" => "sardonyx"}}]}},
        %{bool: %{must: [
          %{bool: %{must_not: [%{term: %{"tags" => "ruby"}}]}},
          %{bool: %{must_not: [%{term: %{"tags" => "sapphire"}}]}},
          %{bool: %{must_not: [%{term: %{"tags" => "pearl"}}]}}
        ]}}
      ]}}
  end

  test "parenthesized expressions" do
    assert query("sardonyx, (ruby | sapphire | pearl)", "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => "sardonyx"}},
        %{bool: %{should: [
          %{term: %{"tags" => "ruby"}},
          %{term: %{"tags" => "sapphire"}},
          %{term: %{"tags" => "pearl"}}
        ]}}
      ]}}
  end

  test "nested parenthesized expressions" do
    assert query("pearl, (nested | - ( -(ruby | sapphire), pearl) )", "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => "pearl"}},
        %{bool: %{should: [
          %{term: %{"tags" => "nested"}},
          %{bool: %{must_not: [
            %{bool: %{must_not: [
              %{bool: %{should: [
                %{term: %{"tags" => "ruby"}},
                %{term: %{"tags" => "sapphire"}}
              ]}}
            ]}},
            %{term: %{"tags" => "pearl"}}
          ]}}
        ]}}
      ]}}
  end

  test "terms with balanced parentheses" do
    assert query("pearl (yellow diamond), (pearl (blue diamond) | pearl)", "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => "pearl (yellow diamond)"}},
        %{bool: %{should: [
          %{term: %{"tags" => "pearl (blue diamond)"}},
          %{term: %{"tags" => "pearl"}}
        ]}}
      ]}}
  end

  test "quoted terms" do
    assert query(~S{"\"quoted\" string", (pearl | "special characters =(")}, "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => ~S{"quoted" string}}},
        %{bool: %{should: [
          %{term: %{"tags" => "pearl"}},
          %{term: %{"tags" => "special characters =("}}
        ]}}
      ]}}
  end

  test "simple field queries" do
    assert query("date:3 years ago", "tags", [], fn(_, _, _) -> nil end) ==
      %{term: %{"tags" => "date:3 years ago"}}

    assert query("date:3 years ago", "tags", ["date"],
      fn
        ("date", _, val) -> %{term: %{"date" => val}}
      end) ==
      %{term: %{"date" => "3 years ago"}}

    assert query("-date: 3 years ago", "tags", ["date"],
      fn
        ("date", _, val) -> %{term: %{"date" => val}}
      end) ==
      %{bool: %{must_not: [
        %{term: %{"date" => "3 years ago"}}
      ]}}
  end

  test "field queries require a delimiter" do
    assert query("date 3 years ago, date:3 years ago", "tags", ["date"],
      fn
        ("date", _, val) -> %{term: %{"date" => val}}
      end) ==
      %{bool: %{must: [
        %{term: %{"tags" => "date 3 years ago"}},
        %{term: %{"date" => "3 years ago"}}
      ]}}
  end

  test "field queries as a part of a complex expression" do
    assert query("ruby, sapphire, -(date:3 days ago | stars:5 | pearl)", "tags",
      ["date", "stars"], fn
        ("date", _, val) -> %{term: %{"date" => val}}
        ("stars", _, val) -> %{term: %{"stars" => val}}
      end) ==
      %{bool: %{must: [
        %{term: %{"tags" => "ruby"}},
        %{term: %{"tags" => "sapphire"}},
        %{bool: %{must_not: [
          %{bool: %{should: [
            %{term: %{"date" => "3 days ago"}},
            %{term: %{"stars" => "5"}},
            %{term: %{"tags" => "pearl"}}
          ]}}
        ]}}
      ]}}
  end

  test "field queries with a qualifier" do
    assert query("date:earlier than 3 years ago", "tags", ["date"],
      fn
        ("date", "earlier than", val) -> %{range: %{date: %{lt: val}}}
      end) ==
      %{range: %{date: %{lt: "3 years ago"}}}

    assert query("stars:   more than   50", "tags", ["stars"],
      fn
        ("stars", "more than", val) -> %{range: %{stars: %{gt: val}}}
      end) ==
      %{range: %{stars: %{gt: "50"}}}

    assert query("date: later than 2016, stars:less than 10", "tags",
      ["date", "stars"], fn
        ("date", "later than", val) -> %{range: %{date: %{gt: val}}}
        ("stars", "less than", val) -> %{range: %{stars: %{lt: val}}}
      end) ==
      %{bool: %{must: [
        %{range: %{date: %{gt: "2016"}}},
        %{range: %{stars: %{lt: "10"}}}
      ]}}
  end

  test "whitespace" do
    assert query("sapphire  ,    ruby       |   -    pearl", "tags") ==
      %{bool: %{should: [
        %{bool: %{must: [
          %{term: %{"tags" => "sapphire"}},
          %{term: %{"tags" => "ruby"}}
        ]}},
        %{bool: %{must_not: [
          %{term: %{"tags" => "pearl"}}
        ]}}
      ]}}

    assert query("sapphire,ruby|-pearl", "tags") ==
      %{bool: %{should: [
        %{bool: %{must: [
          %{term: %{"tags" => "sapphire"}},
          %{term: %{"tags" => "ruby"}}
        ]}},
        %{bool: %{must_not: [
          %{term: %{"tags" => "pearl"}}
        ]}}
      ]}}

    assert query("  pearl ( yellow    diamond )   ,(   pearl (blue diamond)   |pearl) ", "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => "pearl ( yellow    diamond )"}},
        %{bool: %{should: [
          %{term: %{"tags" => "pearl (blue diamond)"}},
          %{term: %{"tags" => "pearl"}}
        ]}}
      ]}}
  end

  test "mutliple disjunction/conjunction clauses" do
    assert query("pearl, amethyst, garnet, -ruby, -sapphire", "tags") ==
      %{bool: %{must: [
        %{term: %{"tags" => "pearl"}},
        %{term: %{"tags" => "amethyst"}},
        %{term: %{"tags" => "garnet"}},
        %{bool: %{must_not: [
          %{term: %{"tags" => "ruby"}}
        ]}},
        %{bool: %{must_not: [
          %{term: %{"tags" => "sapphire"}}
        ]}}
      ]}}
  end

  test "imbalanced parantheses" do
    assert_raise Elasticfusion.Search.ImbalancedParenthesesError, fn ->
      query("(peridot OR lapis lazuli", "tags")
    end
  end
end
