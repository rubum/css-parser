defmodule CssParser.MixProject do
  use Mix.Project
  
  @source_url "https://github.com/rubum/css-parser"
  @version "0.1.0"

  def project do
    [
      app: :css_parser,
      version: @version,
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
      
      # Hex
      description: "Provides css parsing in Elixir",
      package: package(),

      # Docs
      name: "CssParser",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
  
  defp package do
    [
      maintainers: ["Kenneth Mburu"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(.formatter.exs mix.exs README.md lib test) ++
        ~w(priv mix.exs README* readme* LICENSE* license* CHANGELOG* changelog* src),
    ]
  end
  
  defp docs do
    [
      main: "CssParser",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end 
end
