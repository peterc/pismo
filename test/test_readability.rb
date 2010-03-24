require 'helper'

class TestReadability < Test::Unit::TestCase
  context "Readability" do
    setup do
      @simple_html_fixture = <<-HTML
        <html>
          <head>
            <title>title!</title>
          </head>
          <body class='comment'>
            <div>
              <p class='comment'>a comment</p>
              <div class='comment' id='body'>real content</div>
              <div id="contains_blockquote"><blockquote>something in a table</blockquote></div>
            </div>
          </body>
        </html>
      HTML
    end

    context "transformMisusedDivsIntoParagraphs" do
      setup do
        @doc = Readability::Document.new(@simple_html_fixture)
        @doc.transform_misused_divs_into_paragraphs!
      end

      should "transform divs containing no block elements into <p>s" do
        assert_equal "p", @doc.html.css("#body").first.name 
      end

      should "not transform divs that contain block elements" do
        assert_equal "div", @doc.html.css("#contains_blockquote").first.name
      end
    end
    
    context "score_node" do
      setup do
        @doc = Readability::Document.new(<<-HTML)
          <html>
            <body>
              <div id='elem1'>
                <p>some content</p>
              </div>
              <th id='elem2'>
                <p>some other content</p>
              </th>
            </body>
          </html>
        HTML
        @elem1 = @doc.html.css("#elem1").first
        @elem2 = @doc.html.css("#elem2").first
      end

      should "like <div>s more than <th>s" do
        assert @doc.score_node(@elem1)[:content_score] > @doc.score_node(@elem2)[:content_score]
      end

      should "like classes like text more than classes like comment" do
        @elem2.name = "div"
        assert_equal @doc.score_node(@elem2)[:content_score], @doc.score_node(@elem1)[:content_score]
        @elem1['class'] = "text"
        @elem2['class'] = "comment"
        assert @doc.score_node(@elem1)[:content_score] > @doc.score_node(@elem2)[:content_score]
      end
    end

    context "remove_unlikely_candidates!" do
      setup do
        @doc = Readability::Document.new(@simple_html_fixture)
        @doc.remove_unlikely_candidates!
      end

      should "remove things that have class comment" do
        assert @doc.html.inner_html !~ /a comment/
      end

      should "not remove body tags" do
        assert @doc.html.inner_html =~ /<\/body>/
      end

      should "not remove things with class comment and id body" do
        assert @doc.html.inner_html =~ /real content/
      end
    end

    context "score_paragraphs" do
      setup do
        @doc = Readability::Document.new(%{
          <html>
            <head>
              <title>title!</title>
            </head>
            <body id="body">
              <div id="div1">
                <div id="div2>
                  <p id="some_comment">a comment</p>
                </div>
                <p id="some_text">some text</p>
              </div>
              <div id="div3">
                <p id="some_text2">some more text</p>
              </div>
            </body>
          </html>
        })
        @candidates = @doc.score_paragraphs(0)
      end

      should "score elements in the document" do
        assert_equal 3, @candidates.values.length
      end

      should "prefer the body in this particular example" do
        assert_equal "body", @candidates.values.sort { |a, b|
          b[:content_score] <=> a[:content_score]
        }.first[:elem][:id]
      end
    end

    context "the cant_read.html fixture" do
      should "work on the cant_read.html fixture with some allowed tags" do
        allowed_tags = %w[div span table tr td p i strong u h1 h2 h3 h4 pre code br a]
        allowed_attributes = %w[href]
        html = File.read(HTML_DIRECTORY + "/cant_read.html")
        assert Readability::Document.new(html, :tags => allowed_tags, :attributes => allowed_attributes).content.match(/Can you talk a little about how you developed the looks for the/)
      end
    end

    context "general functionality" do
      setup do
        @doc = Readability::Document.new("<html><head><title>title!</title></head><body><div><p>Some content</p></div></body>",
                                         :min_text_length => 0, :retry_length => 1)
      end

      should "return the main page content" do
        assert @doc.content.match("Some content")
      end
    end

    context "ignoring sidebars" do
      setup do
        @doc = Readability::Document.new("<html><head><title>title!</title></head><body><div><p>Some content</p></div><div class='sidebar'><p>sidebar<p></div></body>",
                                         :min_text_length => 0, :retry_length => 1)
      end

      should "not return the sidebar" do
        assert !@doc.content.match("sidebar")
      end
    end    
  end
end