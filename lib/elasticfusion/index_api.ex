defmodule Elasticfusion.IndexAPI do
  def create_index(index) do
    with :ok <- create_index_only(index),
         :ok <- put_mapping(index),
     do: :ok
  end

  def create_index_only(index) do
    status(Elastix.Index.create(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      index.settings()))
  end

  def put_mapping(index) do
    status(Elastix.Mapping.put(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      index.document_type(),
      %{properties: index.mapping()}))
  end

  def delete_index(index) do
    status(Elastix.Index.delete(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name()))
  end

  defp status({:ok, %HTTPoison.Response{status_code: 200}}), do: :ok
  defp status({:ok, error_response}), do: {:error, error_response}
  defp status(connection_error), do: connection_error
end
