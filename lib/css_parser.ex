defmodule CssParser do
  import CssParser.File
  alias CssParser.Cache

  @moduledoc """
  Provides css parsing in Elixir.

  CssParser is based on css.js (a lightweight, battle tested, fast, css parser in JavaScript)
  and implemented for Elixir. More information can be found at https://github.com/jotform/css.js.

  ### On command line
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

    ###

  ### In a module
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
    ###
  """

  @doc """
  Parses a css string to produce selectors, rules/descriptors and types.
  It first tries to remove comments that are of the form:
    ```css
    /* comment */
    ```
  or:
    ```css
    /*
    * other comment here
    */
    ```

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
      ` [:error, "File /path/to/css/file not found."]`

    ###
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

            Map.put(css, "selectors", String.trim(selectors))
            |> Map.put("type", "font-face")
            |> Map.put("descriptors", parse_fonts(rules))

          selectors =~ "@media" ->
            {rules, css} = Map.pop(css, "rules")

            Map.put(css, "selectors", String.trim(selectors))
            |> Map.put("type", "media")
            |> Map.put("children", parse(rules, source: :child))

          true ->
            Map.put(css, "selectors", String.trim(selectors))
            |> Map.put("type", "rules")
        end
    end
  end

  defp parse_rules(%{"rules" => rules} = css) do
    parsed_rules =
      String.trim(rules)
      |> String.split("\n", trim: true)
      |> Enum.join()

    Map.put(css, "rules", parsed_rules)
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
end
