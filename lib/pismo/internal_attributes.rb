# encoding=utf-8

module Pismo
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
    @@phrasie = Phrasie::Extractor.new

    def titles
      @titles ||= Parsers::Titles.call(doc: doc, meta: meta, url: url)
    end

    # Returns the title of the page/content
    def title
      @title ||= Utilities.longest_common_substring_in_array(titles) || titles.first
    end

    # Returns estimate the creation date of page.
    # As clients of this library should be doing HTTP retrieval themselves,
    # they can fall to the Last-Updated HTTP header if they so wish.
    # This method is just rough and based on content-only.
    def datetime
      Parsers::PublishedDate.call(meta: meta, doc: doc, headers: headers)
    end
    alias published_at datetime

    # Returns the author of the page/content
    def authors
      @authors ||= Parsers::Authors.call(doc: doc, meta: meta, url: url, jsonld: jsonld)
    end

    def author
      if authors.keys.count > 1
        authods.dig(authors.keys.detect{|key| key != "publisher/profile"})
      else
        authors
      end
    end

    def descriptions
      @descriptions ||= Parsers::Descriptions.call(doc: doc)
    end

    def description
      descriptions.first
    end

    def ledes
      @ledes ||= Parsers::Ledes.call(doc: doc, reader_doc: reader_doc)
    end

    def lede
      @lede ||= ledes.first
    end
    alias snippet lede

    def ad_networks
      @ad_networks ||= Parsers::AdNetworks.call(doc: doc)
    end

    def meta
      Parsers::Meta.call(doc: doc)
    end

    def jsonld
      @jsonld ||= Parsers::Jsonld.call(doc: doc)
    end

    def headers
      @headers ||= args.dig(:headers) || {}
    end

    # Returns a string containing the first [limit] sentences as determined
    # by the Reader algorithm
    def sentences(limit = 3)
      return nil unless reader_doc && !reader_doc.sentences.empty?

      reader_doc.sentences(limit).join(' ')
    end

    # Returns any images with absolute URLs in the document
    def images(limit = 3)
      if @options[:image_extractor]
        extractor = ImageExtractor.new(self, @url, {
          :min_width => @options[:min_image_width],
          :min_height => @options[:min_image_height],
          :logger => @options[:logger]
          })
        extractor.get_best_images limit
      else
        reader_doc && !reader_doc.images.empty? ? reader_doc.images(limit) : nil
      end
    end

    def videos(limit = 1)
      reader_doc && !reader_doc.videos.empty? ? reader_doc.videos(limit) : nil
    end

   # Returns the tags or categories of the page/content
    def tags
      css_selectors = [
                       '.watch-info-tag-list a',  # YouTube
                       '.entry .tags a',          # Livejournal
                       'a[rel~=tag]',             # Wordpress and many others
                       'a.tag',                   # Tumblr
                       '.tags a',
                       '.labels a',
                       '.categories a',
                       '.topics a'
                      ]

      tags = []

      # grab the first one we get results from
      css_selectors.each do |css_selector|
        tags += @doc.css(css_selector)
        break if tags.any?
      end

      # convert from Nokogiri Element objects to strings
      tags.map!(&:inner_text)

      # remove "#" from hashtag-like tags
      tags.map! { |t| t.gsub(/^#/, '') }

      tags
    end

    def keyword_options
      @keyword_options ||= options.dig(:keyword_options) || {}
    end

    def keywords(method_options = {})
      keyword_parser_options = {
        title: title,
        description: description,
        body: body
      }
      keyword_parser_options = keyword_parser_options.merge(keyword_options)
                                                     .merge(method_options)
      Parsers::Keywords.call(keyword_parser_options)
    end

    def reader_doc
      @reader_doc ||= Reader::Document.create(@doc.to_s, @options)
    end

    # Returns body text as determined by Reader algorithm
    def body
      @body ||= reader_doc.content(true).strip
    end
    alias text body

    # Returns body text as determined by Reader algorithm WITH basic HTML formatting intact
    def html_body
      @html_body ||= reader_doc.content.strip
    end

    def feeds
      @feeds ||= Parsers::Feeds.call(doc: doc)
    end

    def feed
      @feed ||= feeds.first
    end

    def favicons
      @favicons ||= Parsers::Favicons.call(doc: doc, meta: meta)
    end

    def favicon
      @favicon ||= favicons.first
    end
  end
end
