# encoding=utf-8

require 'pismo/title_matches'
require 'pismo/author_matches'
require 'pismo/description_matches'
require 'pismo/lede_matches'


module Pismo
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
    @@phrasie = Phrasie::Extractor.new

    MONTHS_REGEX = %r{(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\.?}i
    DATETIME_REGEXEN = [
      /#{MONTHS_REGEX}\b\s+\d+\D{1,10}\d{4}/i,
      /(on\s+)?\d+\s+#{MONTHS_REGEX}\s+\D{0,10}\d+/i,
      /(on[^\d+]{1,10})\d+(th|st|rd)?.{1,10}#{MONTHS_REGEX}\b[^\d]{1,10}\d+/i,
      /\b\d{4}\-\d{2}\-\d{2}\b/i,
      /\d+(th|st|rd).{1,10}#{MONTHS_REGEX}\b[^\d]{1,10}\d+/i,
      /\d+\s+#{MONTHS_REGEX}\b[^\d]{1,10}\d+/i,
      /on\s+#{MONTHS_REGEX}\s+\d+/i,
      /#{MONTHS_REGEX}\s+\d+/i,
      /\d{4}[\.\/\-]\d{2}[\.\/\-]\d{2}/,
      /\d{2}[\.\/\-]\d{2}[\.\/\-]\d{4}/
    ]

    TITLE_SEPARATORS_REGEX = /\s(\p{Pd}|\:|\p{Pf}|\||\:\:|\.)\s/

    FEED_MATCHES = [
      ['link[@type="application/rss+xml"]',  lambda { |el| el.attr('href') }],
      ['link[@type="application/atom+xml"]', lambda { |el| el.attr('href') }]
    ]

    FAVICON_MATCHES = [
      ['link[@rel="fluid-icon"]', lambda { |el| el.attr('href') }],      # Get a Fluid icon if possible..
      ['link[@rel="shortcut icon"]', lambda { |el| el.attr('href') }],
      ['link[@rel="icon"]', lambda { |el| el.attr('href') }]
    ]

    def titles
      #in order of likley accuracy: og:title, html_title, document matches
      @all_titles ||= begin
        title = [ og_title, html_title, @doc.match(TITLE_MATCHES) ].flatten.compact.uniq
      end
    end

    # Returns the title of the page/content
    def title
      @title ||= begin
        Utilities.longest_common_substring_in_array(titles) || titles.first
      end
    end

    # title from OG tags, if any
    def og_title
      begin
        meta = doc.css("meta[property~='og:title']")

        meta.each do |item|
          next if item["content"].empty?

          return item["content"]
        end
      rescue
        log "Error getting OG tag: #{$!}"
      end
      nil
    end

    # HTML title
    def html_title
      @html_title ||= begin
        if title = @doc.match('title').first
          strip_site_name_and_separators_from(title)
        else
          nil
        end
      end
    end

    def strip_site_name_and_separators_from(title)
      parts = title.split(TITLE_SEPARATORS_REGEX)
      longest = parts.max_by(&:length)
      return longest
    end

    # Return an estimate of when the page/content was created
    # As clients of this library should be doing HTTP retrieval themselves, they can fall to the
    # Last-Updated HTTP header if they so wish. This method is just rough and based on content only.

    def datetime
      datetime = 10
      DATETIME_REGEXEN.detect {|r| datetime = @doc.to_html[r] }

      return unless datetime and datetime.length > 4
      # Clean up the string for use by Chronic
      datetime.strip!
      datetime.gsub!(/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday|mon|tues|tue|weds|wed|thurs|thur|thu|fri|sat|sun)[^\w]*/i, '')
      datetime.sub!(/(on\s+|\,|\.)/, '')
      datetime.sub!(/(\d+)(th|st|rd)/, '\1')
      Chronic.parse(datetime, :context => :past) || datetime
    end

    # Returns the author of the page/content
    def authors
      @all_authors ||= begin
        @doc.match(AUTHOR_MATCHES).map do |author|
          # Strip off any "By [whoever]" section
          case author
          when String
            author.sub!(/^(post(ed)?\s)?by\W+/i, '')
            author.tr!('^a-zA-Z 0-9\'', '|')
            author = author.split(/\|{2,}/).first.to_s
            author.gsub!(/\s+/, ' ')
            author.gsub!(/\|/, '')
            author.strip
          when Array
            author.map! { |a| a.sub(/^(post(ed)?\s)?by\W+/i, '') }.uniq!
          else
            puts "%s is a %s" % [author, author.class]
            nil
          end
        end.compact
      end
    end

    def author
      authors.first
    end

    # Returns the "description" of the page, usually comes from a meta tag
    def descriptions
      @all_descriptions ||= begin
        @doc.match DESCRIPTION_MATCHES
      end
    end

    def description
      descriptions.first
    end

    # Returns the "lede(s)" or first paragraph(s) of the story/page
    LEDE_EXTRACTOR = /^(.*?[\.\!\?]\s){1,3}/m
    def ledes
      @all_ledes ||= begin
        matches = @doc.match(LEDE_MATCHES).map do |lede|
          # TODO: Improve sentence extraction - this is dire even if it "works for now"
          case lede
          when String
            (lede[LEDE_EXTRACTOR] || lede).to_s.strip
          when Array
            lede.map { |l| l.to_s[LEDE_EXTRACTOR].strip || l }.uniq
          end
        end

        if matches.empty?
          if reader_doc and all_sentences = reader_doc.sentences(4)
            unless all_sentences.empty?
              matches.push all_sentences.join(' ')
            end
          end
        end

        matches.uniq
      end
    end

    def lede
      ledes.first
    end

    # Returns a string containing the first [limit] sentences as determined by the Reader algorithm
    def sentences(limit = 3)
      reader_doc && !reader_doc.sentences.empty? ? reader_doc.sentences(limit).join(' ') : nil
    end

    # Returns any images with absolute URLs in the document
    def images(limit = 3)
      if @options[:image_extractor]
        extractor = ImageExtractor.new self, @url, :min_width => @options[:min_image_width], :logger => @options[:logger]
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

    # Returns the "keyword phrases" in the document (not the meta keywords - they're next to useless now)
    DEFAULT_KEYWORD_OPTIONS = { :limit => 20, :minimum_score => "1%" }
    def keywords(options = {})
      options = DEFAULT_KEYWORD_OPTIONS.merge(options)
      text = [title, description, body].join(" ")
      phrases = @@phrasie.phrases(text, :occur => options[:minimum_score]).map {|phrase, occur, strength| [phrase.downcase, occur] }
      phrases.
        delete_if {|phrase, occur| occur < 2 }.
        sort_by   {|phrase, occur| occur     }.
        reverse.first(options[:limit])
    end

    def reader_doc
      @reader_doc ||= Reader::Document.create(@doc.to_s, @options)
    end

    # Returns body text as determined by Reader algorithm
    def body
      @body ||= reader_doc.content(true).strip
    end

    # Returns body text as determined by Reader algorithm WITH basic HTML formatting intact
    def html_body
      @html_body ||= reader_doc.content.strip
    end

    # Returns URL to the site's favicon
    def favicon
      @favicon ||= begin
        url = @doc.match(FAVICON_MATCHES).first
        if url and @url and !url.start_with? "http"
          url = URI.join(@url , url).to_s
        end
        url
      end
    end

    # Returns URL(s) of Web feed(s)
    def feeds
      @all_feeds ||= begin
        @doc.match(FEED_MATCHES).map do |url|
          case url
          when String
            if url.start_with? "http"
              url
            elsif @url
              URI.join(@url , url).to_s
            end
          when Array
            url.map do |u|
              if u.start_with? "http"
                u
              elsif @url
                URI.join(@url, u).to_s
              end
            end.uniq
          end
        end
      end
    end

    def feed
      feeds.first
    end
  end
end
