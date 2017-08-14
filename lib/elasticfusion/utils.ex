defmodule Elasticfusion.Utils do
  @doc """
  A wrapper for `Elastix` requests that returns :ok for
  successful requests and a tuple of {:error, error} otherwise.
  """
  def status({:ok, %HTTPoison.Response{status_code: 200}}), do: :ok
  def status({:ok, %HTTPoison.Response{status_code: 201}}), do: :ok
  def status({:ok, error_response}), do: {:error, error_response}
  def status(connection_error), do: connection_error

  @doc """
  Parses natural language representation of (relative) date,
  e.g. "yesterday", "2 months ago" or "february 2017", and
  returns it as an IS08601-formatted string.

  Internally, this function uses a NIF binding for git date parser,
  https://github.com/ananthakumaran/gate.
  """
  def parse_nl_date(nl_date) do
    nl_date
    |> to_charlist()
    |> :gate.approxidate()
    |> :calendar.now_to_datetime()
    |> NaiveDateTime.from_erl!()
    |> NaiveDateTime.to_iso8601()
  end
end
