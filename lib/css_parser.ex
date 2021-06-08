defmodule CssParser do
  import CssParser.File
  alias CssParser.Cache

  @moduledoc """
  Provides css parsing in Elixir.

  CssParser is based on css.js (a lightweight, battle tested, fast, css parser in JavaScript)
  and implemented for Elixir. More information can be found at https://github.com/jotform/css.js.

  ### Adding CssParser

  To add CssParser to an application, add it to `deps` in the mix.exs file:

  ```elixir
    defp deps do
    [
      {:css_parser, ">= 0.1.0"}
    ]
  end
  ```

  ### Usage
  You can use CssParser either on a command line or a module.

  #### On command line
      iex> CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")
      [
        %{
          "rules" => "color: blue; font-size: 20px;",
          "selectors" => "h4, h3",
          "type" => "rules"
        }
      ]

    You can also parse css from a file as follows:

      iex> CssParser.parse("/path/to/css/file", source: :file)

  #### In a module
    CssParser can be `alias`ed or `import`ed in a module:
    ```elixir
    defmodule MyMod do
      import CssParser

      def my_css_parser(css_string) do
        # use the imported `parse` function
        parse(css_string)
      end
    end
    ```
  """

  @doc """
  Parses a css string to produce selectors, rules/descriptors and types.
  It first tries to remove css comments that might be in the css string.

  ### Options
      * `source: :file` - when set specifies the source of the css to be a file in the given string.

  ### Examples

      iex> CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")
      [
        %{
          "rules" => "color: blue; font-size: 20px;",
          "selectors" => "h4, h3",
          "type" => "rules"
        }
      ]

    You can also parse css from a file as follows:

      iex> CssParser.parse("/path/to/css/file", source: :file)

    In case the file doesn't exist it returns:
      `[:error, "File /path/to/css/file not found."]`

  """

  @css_regex ~r/(?<selectors>[\s\S]*?){(?<rules>[\s\S]*)/i
  @comment_regx ~r/(\/*\*[\s\S]*?\*?\/*)|(\/\*.*?\*\/)/

  @spec parse(String.t(), source: :file | :parent | :child) :: [term()] | [{:error, String.t()}]
  def parse(csstring, opts \\ [])
  def parse(csstring, _opts) when csstring in ["", nil], do: []

  def parse(csstring, opts) do
    # try getting data from cache else initiliaze it
    hash_key = Cache.hash(csstring)

    case Cache.get(hash_key) do
      {:ok, data} ->
        data

      {:error, _} ->
        drop_comments(csstring, opts)
        |> Enum.map(&parse_css/1)
        |> Enum.map(&parse_rules/1)
        |> Cache.save(hash_key, returning: true)
    end
  end

  defp drop_comments(css_string, opts) do
    css_lines = String.split(css_string, "\n", trim: true)

    to_parse =
      Enum.reduce(css_lines, [], fn line, acc ->
        string =
          if Regex.match?(@comment_regx, line) do
            String.split(line, @comment_regx, trim: true)
            |> Enum.reject(&Regex.match?(~r/^[\s\S](?![\s\S]*\{)/, &1))
          else
            line
          end

        [string | acc]
      end)
      |> Enum.reverse()
      |> Enum.join()

    case Keyword.get(opts, :source, :parent) do
      :parent -> String.split(to_parse, ~r/\s*\}\s*|\s*\}\s/, trim: true)
      :child -> String.split(to_parse, ~r/\s*\}\s*|\}/, trim: true)
      :file -> parse_from_file(to_parse)
    end
  end

  defp parse_css(string) when not is_binary(string), do: string

  defp parse_css(string) do
    case Regex.named_captures(@css_regex, string) do
      nil ->
        string

      %{"selectors" => selectors} = css ->
        cond do
          selectors =~ "@font-face" ->
            {rules, css} = Map.pop(css, "rules")

            Map.put(css, :selectors, String.trim(selectors))
            |> Map.put(:type, "font-face")
            |> Map.put(:descriptors, parse_fonts(rules))
            |> Map.drop(["selectors"])

          selectors =~ "@media" ->
            {rules, css} = Map.pop(css, "rules")

            Map.put(css, :selectors, String.trim(selectors))
            |> Map.put(:type, "media")
            |> Map.put(:children, parse(rules, source: :child))
            |> Map.drop(["selectors"])

          true ->
            css |> Map.put(:selectors, selectors)
            |> Map.put(:type, "rules")
            |> Map.drop(["selectors"])
        end
    end
  end

  defp parse_rules(%{"rules" => rules} = css) do
    Map.put(css, :rules, String.split(rules, "  ") |> Enum.join("\t"))
    |> Map.drop(["selectors", "rules"])
  end

  defp parse_rules(css), do: css

  defp parse_fonts(rules) do
    String.split(rules, ";", trim: true)
    |> Enum.map(&:string.trim/1)
    |> Enum.map(&:re.split(&1, ":", [:trim]))
    |> Enum.map(&map_font/1)
  end

  defp map_font([key, value] = _rule) do
    Map.put(%{}, :string.trim(key), :string.trim(value))
  end

  @doc """
  Converts a parsed css to binary

  #### After running:
      iex> parsed = CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")

  #### You can then run:
      iex> CssParser.to_binary(parsed)
  This reverts/converts the previous parsed css to binary.
  #### The function is especially useful if you need to modify the parsed css structure and then get back a binary.
  """
  def to_binary(parsed_css) do
    Enum.reduce(parsed_css, [], fn  %{type: type, selectors: s} = parsed, acc ->
      case type do
        "rules" ->
          str = IO.iodata_to_binary([s, " {\t", parsed.rules, "\r}\n\n"])
          [str | acc]

        "font-face" ->
          descriptors = insert_font_face(parsed.descriptors)
          str = IO.iodata_to_binary([s, " {\t", descriptors, " \r}\n\n"])
          [str | acc]

        "media" ->
          children = insert_media_children(parsed.children)
          str = IO.iodata_to_binary([s, " {\t", children, " \r}\n\n"])
          [str | acc]
      end
    end)
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp insert_font_face(descriptors) do
    Enum.map(descriptors, fn descriptor  ->
      key = :maps.keys(descriptor) |> hd
      value = :maps.values(descriptor) |> hd

      IO.iodata_to_binary([key, ": ", value, ";", "\n"])
    end)
  end

  defp insert_media_children(rules) do
    Enum.map(rules, fn %{rules: r, selectors: s} ->
      IO.iodata_to_binary(["\r\t", s, " {\t", r, "\r\t}"])
    end)
  end
end
