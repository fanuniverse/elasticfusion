defmodule Elasticfusion.Utils do
  @doc """
  A wrapper for `Elastix` requests that returns :ok for
  successful requests and a tuple of {:error, error} otherwise.
  """
  def status({:ok, %HTTPoison.Response{status_code: 200}}), do: :ok
  def status({:ok, %HTTPoison.Response{status_code: 201}}), do: :ok
  def status({:ok, error_response}), do: {:error, error_response}
  def status(connection_error), do: connection_error
end
