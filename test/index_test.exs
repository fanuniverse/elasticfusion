defmodule Elasticfusion.IndexTest do
  use ExUnit.Case
  import CompileTimeAssertions

  test "index_name, document_type, mapping, serialize_fun are required" do
    assert_compile_time_raise RuntimeError,
      "index_name is not specified; set it using `index_name/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index
        end
      end)

    assert_compile_time_raise RuntimeError,
      "document_type is not specified; set it using `document_type/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
        end
      end)

    assert_compile_time_raise RuntimeError,
      "Index mapping is not specified; set it using `mapping/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
          document_type "error_test_type"
        end
      end)

    assert_compile_time_raise RuntimeError,
      "Serialization function is undefined; set it using `serialize/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
          document_type "error_test_type"
          mapping %{}
        end
      end)
  end

  test "index_settings/1 defaults to %{}" do
    defmodule ErrorTestIndex do
      use Elasticfusion.Index

      index_name "error_test_index"
      document_type "error_test_type"
      mapping %{}
      serialize &(&1)
    end

    assert ErrorTestIndex.index_settings() == %{}
  end

  test "mapping/1 ensures that all keys are binaries" do
    assert_compile_time_raise RuntimeError,
      "You must use binaries for mapping fields", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
          document_type "error_test_type"
          mapping %{field: %{type: :keyword}}
        end
      end)
  end

  test "keyword_field/1 ensures that the field is present in the mapping" do
    assert_compile_time_raise RuntimeError,
      "Keyword field is not present in the mapping defined in `mapping/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
          document_type "error_test_type"
          mapping %{"field" => %{type: :keyword}}
          serialize &(%{"field" => &1.field})

          keyword_field "fieldd"
        end
      end)
  end

  test "queryable_fields/1 ensures that all fields are present in the mapping" do
    assert_compile_time_raise RuntimeError,
      "Queryable field `date` is not present in the mapping defined in `mapping/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
          document_type "error_test_type"
          mapping %{"field" => %{type: :keyword}}
          serialize &(%{"field" => &1.field})

          queryable_fields ~w(field date)
        end
      end)

    assert_compile_time_raise RuntimeError,
      "Type declaration for queryable field `date` is not present in the mapping defined in `mapping/1`", (quote do
        defmodule ErrorTestIndex do
          use Elasticfusion.Index

          index_name "error_test_index"
          document_type "error_test_type"
          mapping %{"date" => %{}}
          serialize &(%{"date" => &1.field})

          queryable_fields ~w(date)
        end
      end)
  end
end
