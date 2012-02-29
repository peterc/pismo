# This image extraction algorithm was ported (in part) from the one found in the Goose Library (https://github.com/tomazk/goose)

require 'fastimage'
require 'logger'

# 
# This image extractor will attempt to find the best image nearest the article.
# It uses the fastimage library to quickly check the dimensions of the image, and uses some simple hueristics to score images and pick the best one.
#
class ImageExtractor

  attr_reader :doc, :top_content_candidate, :bad_image_names_regex, :image, :url, :min_width, :min_bytes, :max_bytes, :options, :logger

  def initialize(document, url, options = {})
    @logger = Logger.new(STDOUT)
    
    @options = options
    @bad_image_names_regex = ".html|.gif|.ico|button|twitter.jpg|facebook.jpg|digg.jpg|digg.png|delicious.png|facebook.png|reddit.jpg|doubleclick|diggthis|diggThis|adserver|/ads/|ec.atdmt.com|mediaplex.com|adsatt|view.atdmt"
    @image = nil
    @images = []
    @doc =  Nokogiri::HTML(document.raw_content, nil, 'utf-8')
    @url = url
    @min_width = options[:min_width] || 100
    @top_content_candidate = document.content_at(0)
    @max_bytes = options[:max_bytes] || 15728640
    @min_bytes = options[:min_bytes] || 5000
  end

  def getBestImages(limit = 3)
    @logger.debug("Starting to Look for the Most Relavent Images (min width #{min_width})") 
    checkForLargeImages(top_content_candidate, 0, 0)
    checkForMetaTags unless image
    
    return @images[0...limit].map{|i| buildImagePath(i.first['src']) }
  end

  def getBestImage
    return getBestImages(1)
  end

  def checkForMetaTags
    return true if (checkForLinkTag || checkForOpenGraphTag)

    @logger.debug("unable to find meta image tag")
    return false
  end
  
  #  checks to see if we were able to find open graph tags on this page
  def checkForOpenGraphTag
    begin
      meta = doc.css("meta[property~='og:image']")
      meta.each do |item|
        next if (item["content"].length < 1)

        @image = buildImagePath(item["content"])
        @logger.debug("open graph tag found, using it")
        break
      end
    rescue
      @logger.debug "Error getting OG tag: #{$!}"
    end
    return image ? true : false
  end


  # checks to see if we were able to find link tags on this page
  def checkForLinkTag
    begin
      meta = doc.css("link[rel~='image_src']")
      meta.each do |item|
        next if (item["href"].length < 1) 

        @image = buildImagePath(item["href"])
        @logger.debug("link tag found, using it")
        break
      end
    rescue
      @logger.debug "Error getting link tag: #{$!}"
    end
    return image ? true : false
  end
  
  
  #  * 1. get a list of ALL images from the parent node
  #  * 2. filter out any bad image names that we know of (gifs, ads, etc..)
  #  * 3. do a head request on each file to make sure it meets our bare requirements
  #  * 4. any images left over, use fastimage to check their dimensions
  #  * 5. Score images based on different factors like relative height/width
  def checkForLargeImages(node, parentDepth, siblingDepth)
    images = []

    begin
      images = node.css("img")
    rescue
      @logger.debug "Ooops: #{$!}"
    end

    @logger.debug("checkForLargeImages: Checking for large images, found: " + images.size.to_s + " - parent depth: " + parentDepth.to_s + " sibling depth: " + siblingDepth.to_s)

    goodImages = filterBadNames(images)
      
    @logger.debug("checkForLargeImages: After filterBadNames we have: " + goodImages.size.to_s)

    goodImages = findImagesThatPassByteSizeTest(goodImages)
    
    @logger.debug("checkForLargeImages: After findImagesThatPassByteSizeTest we have: " + goodImages.size.to_s);

    imageResults = downloadImagesAndGetResults(goodImages, parentDepth)

    # // pick out the image with the highest score

    highScoreImage = nil
    imageResults = imageResults.sort_by{|imageResult| 
      imageResult.last
    }
    @images = imageResults
    
    # imageResults.each do |imageResult|      
    #   if !highScoreImage
    #     highScoreImage = imageResult
    #   else
    #     if imageResult.last > highScoreImage.last
    #       highScoreImage = imageResult
    #     end
    #   end
    # end
    highScoreImage = imageResults.first if imageResults.any?
    
    if (highScoreImage)
      @image = buildImagePath(highScoreImage.first["src"])
      @logger.debug("High Score Image is: " + buildImagePath(highScoreImage.first["src"]) )
    else
      @logger.debug("unable to find a large image, going to fall back mode. depth: " + parentDepth.to_s)

      if (parentDepth < 2)
        # // we start at the top node then recursively go up to siblings/parent/grandparent to find something good
        prevSibling = node.previous_sibling
        if (prevSibling)
          @logger.debug("About to do a check against the sibling element, class: " + (prevSibling["class"]||'none') + "' id: '" + (prevSibling["id"]||'none') + "'")
          siblingDepth = siblingDepth + 1
          checkForLargeImages(prevSibling, parentDepth, siblingDepth)
        else
          @logger.debug("no more sibling nodes found, time to roll up to parent node")
          parentDepth = parentDepth + 1
          checkForLargeImages(node.parent, parentDepth, siblingDepth)
        end
      end
    end
  end



  #  loop through all the images and find the ones that have the sufficient bytes to even make them a candidate
  def findImagesThatPassByteSizeTest(images)
    cnt = 0
    if (cnt > 30)
      @logger.debug("Abort! they have over 30 images near the top node: ")
      return goodImages
    end
    
    goodImages = []
    images.each do |image|
      bytes = getBytesForImage(image["src"])

      if ((bytes == 0 || bytes > min_bytes) && bytes < max_bytes)
        @logger.debug("findImagesThatPassByteSizeTest: Found potential image - size: " + bytes.to_s + " src: " + image["src"] )
        goodImages << image
      end
      cnt = cnt + 1
    end
    return goodImages
  end


  #  * takes a list of image elements and filters out the ones with bad names
  def filterBadNames(images)
    goodImages = []
    images.each do |image|
      if (isOkImageFileName(image))
        goodImages << image
      end
    end
    return goodImages
  end

  #  * check the image src against a list of bad image files we know of like buttons, etc...
  def isOkImageFileName(imageNode)
    return false if imageNode["src"].length.eql?(0)
    
    regexp = Regexp.new(bad_image_names_regex)
    if imageNode["src"].match(regexp)
      @logger.debug("Found bad filename for image: " + imageNode['src'])
      return false
    end
    
    return true
  end



  #  * Takes an image path and builds out the absolute path to that image
  #  * using the initial url we crawled so we can find a link to the image if they use relative urls like ../myimage.jpg
  def buildImagePath(image_src)
    newSrc = image_src.gsub(" ", "%20")
    if !newSrc.include?('http')
      newSrc = URI.join(url, newSrc).to_s
    end
    return newSrc
  end


  #  * does the HTTP HEAD request to get the image bytes for this images
  def getBytesForImage(src)
    bytes = 0

    begin
      link = buildImagePath(src)
      link = link.gsub(" ", "%20")

      uri = URI.parse(link)
      req = Net::HTTP.new(uri.host, 80)
      resp = req.request_head(uri.path)

      bytes = min_bytes + 1

      currentBytes = resp.content_length
      
      contentType = resp.content_type;
      if (contentType.include?("image"))
        bytes = currentBytes
      end

    rescue
      @logger.debug "Error getting image size for #{src} - #{$!}"
    end

    return bytes
  end

  #  * Get real image dimensions using fastimage
  #  * we're going to score the images in the order in which they appear so images higher up will have more importance,
  #  * we'll count the area of the 1st image as a score of 1 and then calculate how much larger or small each image after it is
  #  * we'll also make sure to try and weed out banner type ad blocks that have big widths and small heights or vice versa
  #  * so if the image is 3rd found in the dom it's sequence score would be 1 / 3 = .33 * diff in area from the first image
  def downloadImagesAndGetResults(images, depthLevel)
    imageResults = []

    cnt = 1
    initialArea = 0

    images.each do |image|
      if (cnt > 30)
        @logger.debug("over 30 images attempted, that's enough for now")
        break
      end

      begin
        imageSource = buildImagePath(image["src"])
        
        width, height = FastImage.size(imageSource)
        type = FastImage.type(imageSource)
        
        if (width < min_width)
          @logger.debug(image["src"] + " is too small width: " + width.to_s + " skipping..")
          next
        end

        sequenceScore = 1 / cnt
        area = width * height

        totalScore = 0
        if (initialArea == 0)
          initialArea = area
          totalScore = 1
        else
          # // let's see how many times larger this image is than the inital image
          areaDifference = area / initialArea
          totalScore = sequenceScore * areaDifference
        end

        @logger.debug(imageSource + " Area is: " + area.to_s + " sequence score: " + sequenceScore.to_s + " totalScore: " + totalScore.to_s)

        cnt = cnt + 1
        imageResults << [image, totalScore]
      rescue
        @logger.debug "Error scoring image #{image['src']} - #{$!}"
      end
    end

    return imageResults
  end

end