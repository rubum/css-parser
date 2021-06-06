defmodule CssParser.Cache do
  @moduledoc """
  Caching for parsed css
  """

  @doc """
  Create an MD5 hash for indexing parsed data
  """
  @spec hash(String.t()) :: binary()
  def hash(css), do: :crypto.hash(:md5, css)

  @doc """
  Get previsously parsed data using a hask of the css string
  """

  @spec get(binary()) :: {:ok | :error, [] | [term()]}
  def get(key) do
    if table_exists?(:parsed) do
      do_get(key)
    else
      create_table()
      {:error, []}
    end
  end

  defp do_get(key) do
    case :ets.lookup(:parsed, key) do
      [{_key, parsed_data}] -> {:ok, parsed_data}
      whatever_else -> {:error, whatever_else}
    end
  end

  @doc """
  Insert the parsed css into ets cache using hash key of the css string
  """

  @spec save([term()], binary(), [{atom(), any()}]) :: [term()]
  def save(parsed_data, key, returning: true) do
    :ets.insert(:parsed, {key, parsed_data})
    # return the parsed data
    parsed_data
  end

  def save(parsed_data, key, returning: false) do
    :ets.insert(:parsed, {key, parsed_data})
  end

  defp table_exists?(tab) do
    case :ets.whereis(tab) do
      :undefined -> false
      _reference -> true
    end
  end

  defp create_table(options \\ [:named_table]) do
    :ets.new(:parsed, options)
  end
end
