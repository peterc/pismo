# encoding=utf-8

module Pismo
  # Attributes that are "native" to the page, with a minmal amount of
  # processing to make them more useful
  module PageAttributes
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

    def descriptions
      @descriptions ||= Parsers::Descriptions.call(doc: doc)
    end

    def description
      descriptions.first
    end

    # Grabs all the meta from the header and parses it into a hash we can
    # access
    def meta
      Parsers::Meta.call(doc: doc)
    end

    # Grabs all the jsonld in the header and parses it into a hash we can
    # use for retrieving data
    def jsonld
      @jsonld ||= Parsers::Jsonld.call(doc: doc)
    end

    # If the headers are passed into the Pismo document, we can access these
    # through this attribute.
    def headers
      @headers ||= args.dig(:headers) || {}
    end

    # Parses and absoutizes the links on the page
    def links
      @links ||= Parsers::Links.call(url: url, doc: doc)
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

    def html
      @html ||= doc.to_html
    end

    def text
      @text ||= Utilities.sentences_from_node(doc).join(' ')
    end
    alias plain_text text
    alias body text
  end
end
