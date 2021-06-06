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
      deps: deps(),
      
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
      {:ex_doc, "~> 0.20", only: :docs}
    ]
  end
  
  defp package do
    [
      maintainers: ["Kenneth Mburu"],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url},
      files:
        ~w(.formatter.exs mix.exs README.md LICENSE.md lib test),
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
