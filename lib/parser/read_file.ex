defmodule CssParser.File  do
  @moduledoc """
   File reading helper for css parsing.
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
        message: "File #{path} not found."
    end
  end
end
