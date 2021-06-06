# CssParser

**CssParser** provides css parsing in Elixir.
An example follows below:

```elixir
iex> CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")
     [
       %{
         "rules" => "color: blue; font-size: 20px;",
         "selectors" => "h4, h3",
         "type" => "rules"
       }
     ]
```

CssParser can even remove comments from a css string, as below:

```elixir
iex> CssParser.parse("/* first comment */ p {font-weight: bold;} /* second comment */")
     [
      %{
        "rules" => "font-weight: bold;", "selectors" => "p", "type" => "rules"
       }
     ]
```

If you have a file with css, CssParser can parse it as long as you tell it by passing option `source: :file`:

```elixir
iex> CssParser.parse("/some/file/with.css", source: :file)
```
In case the passed css file doesn't exist, you get the following result:

```elixir
iex> CssParser.parse("/non/existing/file.css", source: :file)
     [error: "File /non/existing/file.css" not found."]
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `css_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:css_parser, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/css_parser](https://hexdocs.pm/css_parser).

