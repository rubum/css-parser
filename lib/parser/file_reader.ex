defmodule CssParser.File  do
  @moduledoc """
   File reading helper for css parsing.
  """

  def parse_from_file(path) do
    case File.read(path) do
      {:ok, file} -> CssParser.parse(file)
      {:error, _} -> [{:error, "File #{path} not found."}]
    end
  end
end
