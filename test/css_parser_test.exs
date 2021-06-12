defmodule CssParserTest do
  use ExUnit.Case
  # doctest CssParser
  @css """
  /* first comment */  p {font-weight: bold;}  /* second comment */
  /*
  * comment one here
  */

  h4, h3 {
    color: blue;
    font-size: 20px;
  }

  h1{
    color: red;
    font-size: 25px;
  }

  /* inner comment */

  @media (max-width: 600px) {
    .sidebar { display: none;}
    .main {display: visible;
    }
  }

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

  @-webkit-keyframes bounce {
    0%, to {
        transform: translateY(-25%);
        -webkit-animation-timing-function: cubic-bezier(.8, 0, 1, 1);
        animation-timing-function: cubic-bezier(.8, 0, 1, 1)
    }
    50% {
        transform: none;
        -webkit-animation-timing-function: cubic-bezier(0, 0, .2, 1);
        animation-timing-function: cubic-bezier(0, 0, .2, 1)
    }
  }

  @keyframes bounce {
      0%, to {
          transform: translateY(-25%);
          -webkit-animation-timing-function: cubic-bezier(.8, 0, 1, 1);
          animation-timing-function: cubic-bezier(.8, 0, 1, 1)
      }
      50% {
          transform: none;
          -webkit-animation-timing-function: cubic-bezier(0, 0, .2, 1);
          animation-timing-function: cubic-bezier(0, 0, .2, 1)
      }
  }
  """
  @css1 "/* comment here */\n  h1, h4\n{color: red;\nfont-size: 25px;\n}"

  describe "css parsing" do
    test "removes comments" do
      parsed =
        "/* first comment */ p {font-weight: bold;} /* second comment */"
        |> CssParser.parse()

      assert parsed == [%{rules: "font-weight: bold;", selectors: " p", type: "elements"}]
    end

    test "returns rules, selectors and type" do
      [map_result] = result = CssParser.parse(@css1)
      assert is_list(result)
      assert map_result[:rules] == "color: red;font-size: 25px;"
      assert map_result[:selectors] == "  h1, h4"
      assert map_result[:type] == "elements"
    end

    test "returns font-face type with descriptors" do
      font_faces =
        CssParser.parse(@css)
        |> Enum.filter(&(&1[:type] =~ "font"))

      assert length(font_faces) == 2
      assert [%{descriptors: _, type: "font_face"}, _] = font_faces
    end

    test "reads file and parses if of valid source" do
      assert CssParser.parse("invalid/css/file.css") == "No such file or directory"

      assert :ok = File.write("/tmp/testing.css", @css)

      media_rules =
        CssParser.parse("/tmp/testing.css")
        |> Enum.find(&(Map.get(&1, :type) =~ "media"))

      assert media_rules ==
               %{
                 children: [
                   %{rules: "display: none;", selectors: ".sidebar", type: "elements"},
                   %{rules: "display: visible;", selectors: ".main", type: "elements"}
                 ],
                 selectors: "@media (max-width: 600px)",
                 type: "media"
               }

      on_exit(fn -> File.rm!("/tmp/testing.css") end)
    end

    test "fetches cache if string previously parsed" do
      hash = CssParser.Cache.hash(@css)

      assert {:error, []} = CssParser.Cache.get(hash)

      #parse the check cache
      CssParser.parse(@css)
      assert {:ok, _} = CssParser.Cache.get(hash)
    end
  end
end
