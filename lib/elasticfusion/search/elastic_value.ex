defmodule Elasticfusion.Search.ElasticValue do
  def es_value(raw_value, field, index) do
    case index.mapping()[field] do
      %{type: :date} ->
        date(raw_value)
      _ ->
        raw_value
    end
  end

  def date(raw_value) do
    raw_value
    |> to_charlist
    |> :gate.approxidate
    |> :calendar.now_to_datetime
    |> NaiveDateTime.from_erl!
    |> NaiveDateTime.to_iso8601
  end
end
