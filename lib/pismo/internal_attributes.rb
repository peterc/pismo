# encoding=utf-8

module Pismo
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
    @@phrasie = Phrasie::Extractor.new

    # Returns the author of the page/content
    def authors
      @authors ||= Parsers::Authors.call(
        doc:             doc,
        meta:            meta,
        url:             url,
        jsonld:          jsonld,
        sentences:       all_sentences,
        social_profiles: social_links,
        microdata:       microdata,
        entities:        entities,
        text:            text
      )
    end

    def author
      if authors.keys.count > 1
        authods.dig(authors.keys.detect{|key| key != "publisher/profile"})
      else
        authors
      end
    end

    def ledes
      @ledes ||= Parsers::Ledes.call(doc: doc, reader_doc: reader_doc)
    end

    def lede
      @lede ||= ledes.first
    end
    alias snippet lede

    def ad_networks
      @ad_networks ||= Parsers::AdNetworks.call(doc: doc, links: links)
    end

    # Returns a string containing the first [limit] sentences as determined
    # by the Reader algorithm
    def sentences(limit = 3)
      return nil unless reader_doc && !reader_doc.sentences.empty?

      all_sentences.take(limit).join(' ')
    end

    # Returns a string containing the first [limit] sentences as determined
    # by the Reader algorithm
    def all_sentences
      @all_sentences ||= Utilities.sentences_from_node(doc)
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

    def social_links
      @social_links ||= links.select { |link| link[:profile] == true }
    end

    # Returns the tags or categories of the page/content
    def tags
      @tags ||= Parsers::Tags.call(doc: doc)
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

    def text
      @text ||= Utilities.sentences_from_node(doc).join(' ')
    end
    alias plain_text text
    alias body text
  end
end
