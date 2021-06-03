defmodule CssParser do

  import CssParser.File

  @moduledoc """
  Documentation for `CssParser`.
  """

  @doc """
  Parses a css string to capture selectors and rules.

  ## Examples

      iex> CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")
      %{"rules" => "", "selector" => "h4, h3 "}

  """

  @css_regex ~r/(?<selectors>[\s\S]*?){(?<rules>[\s\S]*)/i
  # @font_case_regex ~r/(?<family>[\s\S]*?);(?<src>[\s\S]*);/i
  @comment_regx ~r/(\/+\s.*)|(\/\*[\s\S]*?\*\/)/
  # @combined_css_regex ~r/((\s*?(?:\/\*[\s\S]*?\*\/)?\s*?@media[\s\S]*?){([\s\S]*?)}\s*?})|(([\s\S]*?){([\s\S]*?)})/i

  defmacro __using__(_opts) do
    quote do
      import CssParser
    end
  end

  @spec parse(String.t(), List.t()) :: List.t()
  def parse(csstring, opts \\ [])
  def parse(csstring, _opts) when csstring in ["", nil], do: []
  def parse(csstring, opts) do
    Keyword.get(opts, :source, :parent)
    |> case do
      :parent -> String.split(csstring, ~r/\n\s*\}\n|\n\}\n/, trim: true)
      :child -> String.split(csstring, ~r/\n\}\n|\}/, trim: true)
      :file -> parse_from_file(csstring)
    end
    |> Enum.reject(&Regex.match?(@comment_regx, &1)) #remove comments if any
    |> Enum.map(&parse_css/1)
    |> Enum.map(&parse_rules/1)
  end

  defp parse_css(string) when not is_binary(string), do: string
  defp parse_css(string) do
    %{"selectors" => selectors} = css = Regex.named_captures(@css_regex, string)

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
    Map.put(%{}, "directive", :string.trim(key))
    |> Map.put("value", :string.trim(value))
  end
end
