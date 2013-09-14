require 'helper'

class FeedTest < Test::Unit::TestCase

  context "Pismo::InternalAttributes" do

    setup do
      @doc = File.read 'test/corpus/factor.html'
    end

    should "find feeds" do
      pismo = Pismo::Document.new @doc
      expected = [
        'http://factor-language.blogspot.com/feeds/posts/default?alt=rss',
        'http://factor-language.blogspot.com/feeds/posts/default',
        'http://factor-language.blogspot.com/feeds/657377910223810792/comments/default'
      ]

      assert_equal expected, pismo.feeds
    end

  end

end
