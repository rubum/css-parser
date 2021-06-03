defmodule CssParserTest do
  use ExUnit.Case
  # doctest CssParser

  @css """
  /*
  comment one here
  */

  h4, h3 {
    color: blue;
    font-size: 20px;
  }

  h1{
    color: red;
    font-size: 25px;
  }

  @media (max-width: 600px) {
    .sidebar { display: none;}
    .main {display: visible;
    }
  }

  // comment two follows

  @font-face {
    font-family: "Open Sans";
    src: url("/fonts/OpenSans-Regular-webfont.woff2") format("woff2"),
        url("/fonts/OpenSans-Regular-webfont.woff") format("woff");
  }

  @font-face {
    font-family: "SwitzeraADF";
    src
    : url("SwitzeraADF-Regular.eot");
    src: url("SwitzeraADF-Regular.eot?#iefix") format("embedded-opentype"),
    url("SwitzeraADF-Regular.woff") format("woff"),
    url("SwitzeraADF-Regular.ttf") format("truetype"),
    url("SwitzeraADF-Regular.svg#switzera_adf_regular") format("svg");
    unicode-range: U+590-5FF;
  }

  // let's say we're done
  """

  @css1 "  h1{color: red;font-size: 25px;}"
  @file "nofile"

  test "greets the world" do
    CssParser.parse(@css, source: :parent)
    # |> length()
    |> IO.inspect()
  end
end
