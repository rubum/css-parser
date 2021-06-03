defmodule CssParser.File  do
  @moduledoc """
   Read css from a file and parse
  """

  defmodule NotFoundException do
    defexception [:message]
  end

  def parse_from_file(path) do
    try do
      File.read!(path)
      |> CssParser.parse(source: :parent)
    rescue
      File.Error ->
        raise NotFoundException,
        message: "File at path #{path} not found"
    end
  end
end
