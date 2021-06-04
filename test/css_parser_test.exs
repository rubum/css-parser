defmodule CssParserTest do
  use ExUnit.Case
  # doctest CssParser
  @css """
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
  """
  @css1 "/* comment here */\n  h1, h4\n{color: red;\nfont-size: 25px;\n}"

  describe "css parsing" do
    test "returns rules, selectors and type" do
      [map_result] = result = CssParser.parse(@css1)
      assert is_list(result)
      assert Map.get(map_result, "rules") == "color: red;font-size: 25px;"
      assert Map.get(map_result, "selectors") == "h1, h4"
      assert Map.get(map_result, "type") == "rules"
    end

    test "returns font-face type with descriptors" do
      font_faces =
        CssParser.parse(@css)
        |> Enum.filter(&Map.get(&1, "type") =~ "font")

      assert length(font_faces) == 2
      assert [%{"descriptors" => _, "type" => "font-face"}, _] = font_faces
    end

    test "reads file and parses if of valid source" do
      assert_raise CssParser.File.NotFoundException, fn ->
        CssParser.parse("invalid/css/file/path", source: :file)
      end

      assert :ok = File.write("/tmp/testing.css", @css)

      media_rules =
        CssParser.parse("/tmp/testing.css", source: :file)
        |> Enum.find(&Map.get(&1, "type") =~ "media")

      assert media_rules ==
        %{"children" => [
          %{"rules" => "display: none;", "selectors" => ".sidebar", "type" => "rules"}
          ],
          "selectors" => "@media (max-width: 600px)",
          "type" => "media"
        }

      on_exit(fn -> File.rm!("/tmp/testing.css") end)
    end
  end
end
