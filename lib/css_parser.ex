defmodule CssParser do

  @moduledoc """
  Documentation for `CssParser`.
  """

  @doc """
  Parses a css string to capture selectors and rules.

  ## Examples

      iex> CssParser.parse()
      %{"rules" => "", "selector" => "h4, h3 "}

  """

  @css_regex ~r/(?<selectors>[\s\S]*?){(?<rules>[\s\S]*)/i
  @font_case_regex ~r/(?<family>[\s\S]*?);(?<src>[\s\S]*);/i
  # @combined_css_regex ~r/((\s*?(?:\/\*[\s\S]*?\*\/)?\s*?@media[\s\S]*?){([\s\S]*?)}\s*?})|(([\s\S]*?){([\s\S]*?)})/i

  defmacro __using__(_opts) do
    quote(do: import CssParser)
  end

  def parse(csstring, opts \\ [])
  def parse(csstring, _opts) when csstring in ["", nil], do: []
  def parse(csstring, opts) do
    Keyword.get(opts, :source, :parent)
    |> case do
      :parent -> String.split(csstring, ~r/\n\}\n/, trim: true)
      :child -> String.split(csstring, ~r/\n\}\n|\}/, trim: true)
    end
    |> Enum.map(&parse_css/1)
    |> Enum.map(&parse_rules/1)
  end

  defp parse_css(string) do
    %{"selectors" => selectors} = css = Regex.named_captures(@css_regex, string)

    cond do
      String.contains?(selectors, "@font-face") ->
        {rules, css} = Map.pop(css, "rules")

        Map.put(css, "type", "font-face")
        |> Map.put("descriptors", Regex.named_captures(@font_case_regex, rules))

      String.contains?(selectors, "@media") ->
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
end
