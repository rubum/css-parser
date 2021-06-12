# CssParser

**CssParser** provides css parsing in Elixir.
An example follows below:

```elixir
iex> CssParser.parse("h4, h3 {color: blue; font-size: 20px;}")
     [
      %{
        rules: "color: blue; font-size: 20px;",
        selectors: "h4, h3",
        type: "elements"
      }
    ]
```

CssParser can even remove comments from a css string, as below:

```elixir
iex> CssParser.parse("/* first comment */ p {font-weight: bold;} /* second comment */")
     [
      %{
        rules: "font-weight: bold;", selectors: " p", type: "rules"
       }
     ]
```

If you have a file with css, CssParser can parse it as long as it's a valid source:

```elixir
iex> CssParser.parse("/some/file/with.css")
```
In case the passed css file isn't valid, you get the following result:

```elixir
iex> CssParser.parse("/non/existing/file.css")
     "No such file or directory"
```

## Installation

CssParser can be installed by adding `css_parser` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:css_parser, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/css_parser](https://hexdocs.pm/css_parser).

## Running tests

Clone the repo and fetch its dependencies:

    $ git clone https://github.com/rubum/css-parser.git
    $ cd css-parser
    $ mix deps.get
    $ mix test

## License

Copyright (c) 2020 Rubum

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

