defmodule CssParser.File  do
  @moduledoc """
   File reading and formating helper for the css parser.
  """

  @file_regex ~r/(?:^\/\w)(.*)|(?:^\w+\/)(.*)([^{}[\]]|.$|.css$)/m

  def is_file?(path) do
    File.regular?(path) or File.dir?(path) or Regex.match?(@file_regex, path)
  end

  def format(charlist)  do
    :file.format_error(charlist)
    |> List.to_string
    |> String.capitalize
  end
end
