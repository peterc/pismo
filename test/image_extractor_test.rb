
require 'helper'

class ImageExtractorTest < Test::Unit::TestCase

   context "A blog post with relative images and image_extractor option set to true" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/nymag.html"), :image_extractor => true, :url => "http://nymag.com/blog/post-title")
    end

    should "get image from og:image tag" do
      ImageExtractor.any_instance.stubs(:get_bytes_for_image).returns(5)
      ImageExtractor.any_instance.stubs(:get_bytes_for_image).with('http://www.rubyinside.com/wp-content/uploads/2010/01/cofeescriptdemo.png').returns(200000)
      FastImage.stubs(:size).returns([300, 300])
      FastImage.stubs(:type).returns("image/jpeg")

      assert_equal @doc.images.first, 'http://pixel.nymag.com/imgs/fashion/daily/2012/10/16/16-oprah-terry-richardson.o.jpg/a_2x-square.jpg'
    end

    should "not get og:image image if it's too small" do
      ImageExtractor.any_instance.stubs(:get_bytes_for_image).returns(5)
      ImageExtractor.any_instance.stubs(:get_bytes_for_image).with('http://www.rubyinside.com/wp-content/uploads/2010/01/cofeescriptdemo.png').returns(200000)
      FastImage.stubs(:size).returns([99, 99])
      FastImage.stubs(:type).returns("image/jpeg")

      assert_equal @doc.images.first, nil
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


end
