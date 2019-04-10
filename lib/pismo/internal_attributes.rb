# encoding=utf-8

module Pismo
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
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
      author = authors.find { |hsh| hsh[:type] == 'site/author' }
      author = authors.first if author.nil?
      author
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

    def hosts
      @hosts ||= links.select {|link| link[:profile] == false || link[:profile].nil? }
                      .map { |link| link.dig(:href) }
                      .uniq
                      .map { |link| Addressable::URI.parse(link).host }
                      .delete_if { |h| h.nil? }
                      .uniq
                      .sort
    end

    def domains
      @domains ||= hosts.map { |host| PublicSuffix.domain(host) }
                       .uniq
                       .delete_if(&:nil?)
                       .sort
    end

    def published_date
      @published_date ||= Pismo::Parsers::PublishedDate.new(meta: meta, doc: doc).call
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
    def images
      @images ||= Parsers::Images.call(doc: doc, url: url, meta: meta)
    end

    def image
      @image ||= images&.first
    end

    def videos(limit = 1)
      reader_doc && !reader_doc.videos.empty? ? reader_doc.videos(limit) : nil
    end

    def social_links
      @social_links ||= links.select { |link| link[:profile] == true }
    end
    alias profile_links social_links

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
      @text ||= all_sentences.join(' ')
    end
    alias plain_text text
    alias body text
  end
end
