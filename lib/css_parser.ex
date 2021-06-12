defmodule CssParser do
  import  CssParser.File
  alias CssParser.Cache

  @moduledoc """
  Provides css parsing in Elixir.

  CssParser was inspired by css.js (a lightweight, battle tested, fast, css parser in JavaScript).
  More information can be found at https://github.com/jotform/css.js.

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
          rules: "color: blue; font-size: 20px;",
          selectors: "h4, h3",
          type: "elements"
        }
      ]

    You can also parse css from a file as follows:

      iex> CssParser.parse("/path/to/file.css")

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

  ### Recommendation
  Enusure your css is valid to get valid results. Garbage in (maybe) garbage out.
  Kindly suggest improvements.
  """

  @doc """
  Parses a css string to produce selectors, rules/descriptors and types.
  It first tries to remove css comments that might be in the css string.

  ### Examples

      iex> CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")
      [
        %{
          rules: "color: blue; font-size: 20px;",
          selectors: "h4, h3",
          type: "elements"
        }
      ]

    You can also parse css from a file as follows to get a string:

      iex> CssParser.parse("/path/to/css/file.css")

    In case the file path is invalid you'll get a relevant message such as `No such file or directory`.

  """

  @font_regex ~r/((?=@font-face)(.*?)(\s*\}))/s
  @media_regex ~r/((?=@media)(.*?)(\s*\}){2})/s
  @comment_regx ~r/(\/\*.*?\*\/)/ #~r/(\/*\*[\s\S]*?\*?\/*)|(\/\*.*?\*\/)/
  @keyframe_regex ~r/(\s*(?=\@keyframes|@-webkit-keyframes)(.*?)(\s*\}){2}\s*)+/s
  @element_regex ~r/(?=@media|@keyframe|@-webkit-keyframes|@font-face)(.*?)(\s*\}){2}\s*/s

  @spec parse(binary()) :: [term()] | binary()
  def parse(string) when string in ["", nil], do: []

  def parse(string) do
    if is_file?(string) do
      parse_from_file(string)
    else
      parse_css(string)
    end
  end

  defp parse_from_file(string) do
    case File.read(string) do
      {:ok, content} -> parse_css(content)
      {:error, reason} -> format(reason)
    end
  end

  defp parse_css(string) do
    hash_key = Cache.hash(string)

    case Cache.get(hash_key) do
      {:ok, parsed_data} -> parsed_data

      {:error, _} ->
        string
        |> drop_comments()
        |> tokenize()
        |> Cache.save(hash_key, returning: true)
    end
  end

  # tries to drop existing comments
  defp drop_comments(css_string) do
    String.split(css_string, "\n", trim: true)
    |> Enum.reduce([], fn line, acc ->
      str =
        if Regex.match?(@comment_regx, line) do
          String.replace(line, @comment_regx, "")
        else
          line
        end

      [ str | acc ]
    end)
    |> Enum.reverse()
    |> Enum.join()
  end

  # tokenizes css string into the various css selectors e.g. @media, @font-face, @keyframes and elements
  defp tokenize(css) do
    media =
      Regex.scan(@media_regex, css)
      |> Enum.map(fn media ->
        %{"selector" => selector, "children" => children} =
          Regex.named_captures(~r/(?<selector>(@media)(.*?)(\)))(?<children>.*)/s, hd(media))
        %{selectors: selector, children: parse_elements(children, :children), type: "media"}
      end)

    keyframes =
      Regex.scan(@keyframe_regex, css)
      |> Enum.map(fn keyframe ->
        [name | block] = String.split(hd(keyframe), ~r/(?={)/s, trim: true)
        %{selectors: name, rules: block, type: "keyframe"}
      end)

    font_faces =
      Regex.scan(@font_regex, css)
      |> Enum.map(fn font_face ->
        [name, descriptors] = String.split(hd(font_face), ~r/({)/s, trim: true)
        %{selectors: name, descriptors: descriptors, type: "font_face"}
      end)

    parse_elements(css, :root) ++ media ++ keyframes ++ font_faces
  end

  defp parse_elements(css, type) do
    # strip media-queries, keyframes and font-faces
    case type do
      :root ->
        String.split(css, @element_regex, trim: true)
        # |> IO.inspect()
        |> Enum.flat_map(fn rule ->
            Enum.map(String.split(rule, ~r/\s*\}\s*/, trim: true), fn rule ->
              do_parse_element(rule)
            end)
        end)

      :children ->
        Enum.map(String.split(css, ~r/\s*\}\s*/, trim: true), fn rule ->
          do_parse_element(rule)
        end)
    end
    # remove empty items
    |> Enum.reject(& &1 ==  %{})
  end

  defp do_parse_element(el) do
    case String.split(el, ~r/\s*\{\s*/, trim: true) do
      [r | []] when r in ["", " ", "  ", "   ", "    ", nil] -> %{}
      [selectors, rules] ->
        %{type: "elements", selectors: selectors, rules: rules}
      [universal_rules] ->
        %{type: "universal", selectors: "*", rules: universal_rules}
    end
  end

  @doc """
  Converts a parsed css to binary

  #### After running:
      iex> parsed = CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")

  #### You can then get a (formatted) string as follows:
      iex> CssParser.to_binary(parsed)
          "h4, h3 {\n\t\t\tcolor: blue; font-size: 20px;\r\t\t\s}"
  #### The function is especially useful if you need to modify the parsed css structure and then get back a binary.
  """

  @spec to_binary([map()]) :: binary()
  def to_binary(parsed_css) do
    Enum.reduce(parsed_css, [], fn  %{type: type, selectors: s} = parsed, acc ->
      case type do
        "elements" ->
          str = IO.iodata_to_binary([s, " {\n\t", parsed.rules, "\r}\n\n"])
          [str | acc]

        "keyframe" -> [ IO.iodata_to_binary([s, parsed.rules, "\n\n"]) | acc ]

        "media" ->
          children = insert_media_children(parsed.children)
          str = IO.iodata_to_binary([s, " {\t", children, " \r}\n\n"])
          [str | acc]

        "font_face" ->
          str = IO.iodata_to_binary([s, " {\t", parsed.descriptors, "\n\n"])
          [str | acc]

        "universal" ->
          str = IO.iodata_to_binary([s, " {\t", parsed.rules, "\r}\n\n"])
          [str | acc]
      end
    end)
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp insert_media_children(rules) do
    Enum.map(rules, fn %{rules: r, selectors: s} ->
      IO.iodata_to_binary(["\r\t", s, " {\n\t\t", r, "\r\t}"])
    end)
  end
end
