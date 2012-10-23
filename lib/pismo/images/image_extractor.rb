# This image extraction algorithm was ported (in part) from the one found in the Goose Library (https://github.com/tomazk/goose)

require 'fastimage'
require 'logger'

#
# This image extractor will attempt to find the best image nearest the article.
# It uses the fastimage library to quickly check the dimensions of the image, and uses some simple hueristics to score images and pick the best one.
#
class ImageExtractor

  attr_reader :doc, :top_content_candidate, :bad_image_names_regex, :image, :url, :min_width, :min_height, :min_bytes, :max_bytes, :options, :logger

  def initialize(document, url, options = {})
    @logger = options[:logger]
    @logger = Logger.new(STDERR) if @logger.nil?

    @options = options
    bad_image_names = options[:bad_image_names] || %w"
      .html .gif .ico button twitter.jpg facebook.jpg digg.jpg digg.png delicious.png facebook.png
      reddit.jpg doubleclick diggthis diggThis adserver /ads/ ec.atdmt.com mediaplex.com adsatt view.atdmt"
    @bad_image_names_regex = Regexp.new bad_image_names.map {|n| Regexp.escape(n) }.join("|")
    @images = []
    @doc =  Nokogiri::HTML(document.html, nil, 'utf-8')
    @url = url
    @min_width = options[:min_width] || 100
    @min_height = options[:min_height] || 100
    @top_content_candidate = document.reader_doc.content_at(0)
    @max_bytes = options[:max_bytes] || 15728640
    @min_bytes = options[:min_bytes] || 5000
  end

  def get_best_images(limit = 3)
    return unless @images.empty?

    check_for_large_images(top_content_candidate, 0, 0)

    find_image_from_meta_tags if @images.empty?

    return @images.slice(0, limit)
  end

  def get_best_image
    return get_best_images.first
  end

  private

  def log(*args)
    @logger.debug *args if @logger
  end

  def find_image_from_meta_tags
    img = find_image_from_link_tag || find_image_from_open_graph_tag
    @images.push img
  end

  # Try to find an image from an opengraph tag
  def find_image_from_open_graph_tag
    begin
      meta = doc.css("meta[property~='og:image']")

      meta.each do |item|
        next if item["content"].empty?

        return item["content"]
      end
    rescue
      log "Error getting OG tag: #{$!}"
    end
    nil
  end

  # Try to find an image from a <link> tag
  def find_image_from_link_tag
    begin
      meta = doc.css("link[rel~='image_src']")
      meta.each do |item|
        next if item["href"].empty?

        return item["href"]
      end
    rescue
      log "Error getting link tag: #{$!}"
    end
    nil
  end

  #  * 1. get a list of ALL images from the parent node
  #  * 2. filter out any bad image names that we know of (gifs, ads, etc..)
  #  * 3. do a head request on each file to make sure it meets our bare requirements
  #  * 4. any images left over, use fastimage to check their dimensions
  #  * 5. Score images based on different factors like relative height/width
  def check_for_large_images(node, parent_depth, sibling_depth)
    images = []

    begin
      images = node.css("img").map do |img|
        src = img["src"]
        unless src.start_with?('http')
          if url.nil? or url.empty?
            raise "No URL passed to image extractor; unable to absolutize image URLs"
          else
            src = URI.join(@url, src).to_s
          end
        end
        URI.escape src
      end
    rescue
      log "Oops: #{$!}"
      return []
    end

    images.reject! {|i| !filename_ok? i }

    images = filter_by_filesize(images, min_bytes, max_bytes)

    download_images_and_get_results(images, parent_depth).tap do |results|
      if results.empty?
        if parent_depth < 5
          # We start at the top node then recursively go up to siblings/parent/grandparent to find something good
          if prev_sibling = node.previous_sibling
            check_for_large_images prev_sibling, parent_depth, sibling_depth + 1
          else
            check_for_large_images(node.parent, parent_depth + 1, sibling_depth)
          end
        end
      else
        @images = results
      end
    end
  end

  #  loop through all the images and find the ones that have the sufficient bytes to even make them a candidate
  def filter_by_filesize(images, min_bytes, max_bytes)
    found = 0
    images.map do |image|
      bytes = get_bytes_for_image image
      log "%s bytes - %s" % [bytes, image]
      if found < 20 and bytes and (bytes == 0 or bytes > min_bytes) and bytes < max_bytes
        log "filter_by_filesize: Found potential image - size: #{bytes} bytes, src: #{image}"
        found += 1
        image
      else
        nil
      end
    end.compact
  end

  #  * check the image src against a list of bad image files we know of like buttons, etc...
  def filename_ok?(src)
    return false if src.nil? or src.empty?

    if src.match bad_image_names_regex
      log "Found bad filename for image: #{src}"
      false
    else
      true
    end
  end

  #  Perform an HTTP HEAD request to get the image bytes for this images
  def get_bytes_for_image(src)
    # begin
      uri = URI.parse src
      req = Net::HTTP.new(uri.host, 80)
      resp = req.request_head(uri.path)

      if resp.content_type.include?("image")
        return resp.content_length
      end
    # rescue
    #  log "Error getting image size for #{src} - #{$!}"
    #end

    return 0
  end

  #  * Get real image dimensions using fastimage
  #  * we're going to score the images in the order in which they appear so images higher up will have more importance,
  #  * we'll count the area of the 1st image as a score of 1 and then calculate how much larger or small each image after it is
  #  * we'll also make sure to try and weed out banner type ad blocks that have big widths and small heights or vice versa
  #  * so if the image is 3rd found in the dom it's sequence score would be 1 / 3 = .33 * diff in area from the first image
  def download_images_and_get_results(images, depthLevel)
    results = []

    initial_area = 0

    images.slice(0, 30).each_with_index do |image, index|
      begin
        width, height = FastImage.size image
        type = FastImage.type image

        log "For %s, got w:h [%d, %d], type %s" % [image, width, height, type]

        if width < min_width
          log "#{image} is too small width: #{width}. Skipping."
          next
        end

        if height < min_height
          log "#{image} is too small height: #{height}. Skipping."
          next
        end

        sequence_score = 1 / (index + 1)
        area = width * height

        total_score = 0
        if (initial_area == 0)
          initial_area = area
          total_score = 1
        else
          # // let's see how many times larger this image is than the inital image
          area_difference = area / initial_area
          total_score = sequence_score * area_difference
        end

        log "#{image} Area is: #{area}, sequence score: #{sequence_score}, total score: #{total_score}"

        results << [image, total_score]
      rescue
        log "Error scoring image #{image} - #{$!}"
      end
    end

    results.sort {|a, b| b.last <=> a.last }.map(&:first)
  end

end
