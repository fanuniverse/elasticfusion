defmodule Elasticfusion.Search.ParserTest do
  use ExUnit.Case

  import Elasticfusion.Search.Parser, only: [query: 1, query: 2]

  test "simple terms" do
    assert query("peridot") == "peridot"
    assert query("NOT lapis lazuli") == {:not, "lapis lazuli"}
  end

  test "redundant negation" do
    assert query("NOT NOT NOT NOT peridot") == "peridot"
    assert query("NOT NOT NOT NOT NOT peridot") == {:not, "peridot"}
  end

  test "single conjunction and disjunction" do
    assert query("peridot, lapis lazuli") == {:and, ["peridot", "lapis lazuli"]}
    assert query("peridot | lapis lazuli") == {:or, ["peridot", "lapis lazuli"]}
  end

  test "operator precedence and associativity" do
    assert query("ruby, sapphire, pearl | sardonyx") ==
      {:or,
        [{:and, ["ruby", "sapphire", "pearl"]},
         "sardonyx"]}

    assert query("sardonyx | ruby, sapphire, pearl") ==
      {:or,
        ["sardonyx",
         {:and, ["ruby", "sapphire", "pearl"]}]}

    assert query("-ruby, -sapphire, -pearl | -sardonyx") ==
      {:or,
        [{:and, [{:not, "ruby"}, {:not, "sapphire"}, {:not, "pearl"}]},
         {:not, "sardonyx"}]}

    assert query("-sardonyx | -ruby, -sapphire, -pearl") ==
      {:or,
        [{:not, "sardonyx"},
         {:and, [{:not, "ruby"}, {:not, "sapphire"}, {:not, "pearl"}]}]}
  end

  test "parenthesized expressions" do
    assert query("sardonyx, (ruby | sapphire | pearl)") ==
      {:and,
        ["sardonyx",
         {:or, ["ruby", "sapphire", "pearl"]}]}
  end

  test "nested parenthesized expressions" do
    assert query("pearl, (nested | - ( -(ruby | sapphire), pearl) )") ==
      {:and,
        ["pearl",
         {:or,
          ["nested",
           {:not,
             {:and,
               [{:not, {:or, ["ruby", "sapphire"]}},
                "pearl"]}}]}]}
  end

  test "terms with balanced parentheses" do
    assert query("pearl (yellow diamond), (pearl (blue diamond) | pearl)") ==
      {:and,
        ["pearl (yellow diamond)",
         {:or,
           ["pearl (blue diamond)",
            "pearl"]}]}
  end

  test "quoted terms" do
    assert query(~S{"\"quoted\" string", (pearl | "special characters =(")}) ==
      {:and,
        [~S{"quoted" string},
         {:or,
           ["pearl",
            "special characters =("]}]}
  end

  test "simple field queries" do
    assert query("date:3 years ago", []) == "date:3 years ago"

    assert query("date:3 years ago", [:date]) ==
      {:field_query, "date", nil, "3 years ago"}

    assert query("-date: 3 years ago", ["date"]) ==
      {:not,
        {:field_query, "date", nil, "3 years ago"}}
  end

  test "field queries require a delimiter" do
    assert query("date 3 years ago, date:3 years ago", [:date]) ==
      {:and,
        ["date 3 years ago",
         {:field_query, "date", nil, "3 years ago"}]}
  end

  test "field queries as a part of a complex expression" do
    assert query("ruby, sapphire, -(date:3 days ago | stars:5 | pearl)", [:date, :stars]) ==
      {:and,
        ["ruby",
         "sapphire",
         {:not,
           {:or,
             [{:field_query, "date", nil, "3 days ago"},
              {:field_query, "stars", nil, "5"},
              "pearl"]}}]}
  end

  test "field queries with a qualifier" do
    assert query("date:earlier than 3 years ago", ["date"]) ==
      {:field_query, "date", :lt, "3 years ago"}

    assert query("stars:   more than   50", [:stars]) ==
      {:field_query, "stars", :gt, "50"}

    assert query("date: later than 2016, stars:less than 10", [:date, :stars]) ==
      {:and,
        [{:field_query, "date", :gt, "2016"},
         {:field_query, "stars", :lt, "10"}]}
  end

  test "whitespace" do
    assert query("sapphire  ,    ruby       |   -    pearl") ==
      {:or,
        [{:and, ["sapphire", "ruby"]},
         {:not, "pearl"}]}

    assert query("sapphire,ruby|-pearl") ==
      {:or,
        [{:and, ["sapphire", "ruby"]},
         {:not, "pearl"}]}

    assert query("  pearl ( yellow    diamond )   ,(   pearl (blue diamond)   |pearl) ") ==
      {:and,
        ["pearl ( yellow    diamond )",
         {:or,
           ["pearl (blue diamond)",
            "pearl"]}]}
  end

  test "mutliple disjunction/conjunction clauses" do
    assert query("pearl, ruby, sapphire, -amethyst") ==
      {:and, ["pearl", "ruby", "sapphire", {:not, "amethyst"}]}

    assert query("(ruby | sapphire | pearl, amethyst | garnet), \
(-(peridot | lapis | lazuli) | steven | -gem | diamond), too much?") ==
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
        "too much?"]}
  end

  test "imbalanced parantheses" do
    assert_raise Elasticfusion.Search.ImbalancedParenthesesError, fn ->
      query("(peridot OR lapis lazuli")
    end
  end
end
