require 'helper'

class TestPismoDocument < Test::Unit::TestCase
  context "Pismo::Document" do
    should "process an IO/File object" do
      doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
      assert doc.doc.kind_of?(Nokogiri::HTML::Document)
    end
  end

  context "A very basic Pismo document" do
    setup do
      @doc = Document.new(%{<html><body><h1>Hello</h1></body></html>})
    end

    should "pass sanitization" do
      assert_equal %{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">\n<html><body><h1>Hello</h1></body></html>\n}, @doc.html
    end

    should "result in a Nokogiri document" do
      assert @doc.doc.kind_of?(Nokogiri::HTML::Document)
    end
  end

  context "A basic real world blog post" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
    end

    should "provide a title" do
      assert_equal  "CoffeeScript: A New Language With A Pure Ruby Compiler", @doc.title
    end

    should "provide keywords" do
      assert_equal [["code", 4],
                    ["coffeescript", 3],
                    ["compiler", 2],
                    ["github", 2],
                    ["javascript", 2],
                    ["ruby", 5]], @doc.keywords.sort_by{|p| p[0]}
    end
  end

  context "A basic real world blog post with relative images and all_images option set to true" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/relative_imgs.html"), :all_images => true)
    end

    should "get relative images" do
      assert @doc.images.include?('/wp-content/uploads/2010/01/coffeescript.png')
    end
  end

  context "A basic real world blog post with relative images and image_extractor option set to true" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/relative_imgs.html"), :image_extractor => true, :url => "http://www.rubyinside.com/some/bogus/post/")
    end

    should "scrape images" do
      ImageExtractor.any_instance.stubs(:get_bytes_for_image).returns(5)
      ImageExtractor.any_instance.stubs(:get_bytes_for_image).with('http://www.rubyinside.com/wp-content/uploads/2010/01/cofeescriptdemo.png').returns(200000)
      FastImage.stubs(:size).returns([300, 300])
      FastImage.stubs(:type).returns("image/jpeg")

      assert_equal @doc.images.first, 'http://www.rubyinside.com/wp-content/uploads/2010/01/cofeescriptdemo.png'
    end
  end


  context "A blog post with videos" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/videos.html"))
    end

    should 'get embed object' do
      videos = @doc.videos
      assert_equal videos.length, 1
      assert_equal videos.first['src'], 'http://www.youtube.com/v/dBtYXFXa5Ig?fs=1&hl=en_US&rel=0&color1=0xFFFFFF&color2=0xFFFFFF&border=0'
    end
  end

end