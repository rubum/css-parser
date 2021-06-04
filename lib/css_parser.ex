defmodule CssParser do

  import CssParser.File

  @css_regex ~r/(?<selectors>[\s\S]*?){(?<rules>[\s\S]*)/i
  @comment_regx ~r/(\/*\*[\s\S]*?)/

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

  @spec parse(String.t(), [source: :file | :parent | :child]) :: [Map.t()] | [{:error, String.t()}]
  def parse(csstring, opts \\ [])
  def parse(csstring, _opts) when csstring in ["", nil], do: []
  def parse(csstring, opts) do
    csstring
    |> drop_comments(opts)
    |> Enum.map(&parse_css/1)
    |> Enum.map(&parse_rules/1)
  end

  defp drop_comments(css_string, opts) do
    string =
      String.split(css_string, "\n", trim: true)
      |> Enum.reject(&Regex.match?(@comment_regx, &1))
      |> Enum.join()

    case Keyword.get(opts, :source, :parent) do
      :parent -> String.split(string, ~r/\s*\}\s*|\s*\}\s/, trim: true)
      :child -> String.split(string, ~r/\s*\}\s*|\}/, trim: true)
      :file -> parse_from_file(string)
    end
  end

  defp parse_css(string) when not is_binary(string), do: string
  defp parse_css(string) do
    case Regex.named_captures(@css_regex, string) do
      nil -> string
      %{"selectors" => selectors} = css ->
        cond do
          selectors =~ "@font-face" ->
            {rules, css} = Map.pop(css, "rules")

            Map.put(css, "selectors",  String.trim(selectors))
            |> Map.put("type", "font-face")
            |> Map.put("descriptors", parse_fonts(rules))

          selectors =~ "@media" ->
            {rules, css} = Map.pop(css, "rules")

            Map.put(css, "selectors",  String.trim(selectors))
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
      |> Enum.join

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
