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

    TITLE_MATCHES = [
      '#pname a',                                                       # Google Code style
      '.entryheader h1',                                                # Ruby Inside/Kubrick
      '.entry-title a',                                                 # Common Blogger/Blogspot rules
      '.post-title a',
      '.post_title a',
      '.posttitle a',
      '.post-header h1',
      '.entry-title',
      '.post-title',
      '.post h1',
      '.post h3 a',
      'a.datitle',                                                      # Slashdot style
      '.posttitle',
      '.post_title',
      '.pageTitle',
      '#main h1.title',
      '.title h1',
      '.post h2',
      'h2.title',
      '.entry h2 a',
      '.entry h2',                                                      # Common style
      '.boite_titre a',
      ['meta[@name="title"]', lambda { |el| el.attr('content') }],
      'h1.headermain',
      'h1.title',
      '.mxb h1',                                                        # BBC News
      '#content h1',
      '#content h2',
      '#content h3',
      'a[@rel="bookmark"]',
      '.products h2',
      '.caption h3',
      '#main h2',
      '#body h1',
      '#wrapper h1',
      '#page h1',
      '.asset-header h1',
      '#body_content h2'
    ]

    AUTHOR_MATCHES = [
      '.post-author .fn',
      '.wire_author',
      '.cnnByline b',
      '.editorlink',
      '.authors p',
      ['meta[@name="author"]', lambda { |el| el.attr('content') }],     # Traditional meta tag style
      ['meta[@name="Author"]', lambda { |el| el.attr('content') }],     # CNN style
      ['meta[@name="AUTHOR"]', lambda { |el| el.attr('content') }],     # CNN style
      '.byline a',                                                      # Ruby Inside style
      '.byline',
      '.post_subheader_left a',                                         # TechCrunch style
      '.byl',                                                           # BBC News style
      '.articledata .author a',
      '#owners a',                                                      # Google Code style
      '.author a',
      '.author',
      '.auth a',
      '.auth',
      '.cT-storyDetails h5',                                            # smh.com.au - worth dropping maybe..
      ['meta[@name="byl"]', lambda { |el| el.attr('content') }],
      '.timestamp a',
      '.fn a',
      '.fn',
      '.byline-author',
      '.ArticleAuthor a',
      '.blog_meta a',
      'cite a',
      'cite',
      '.contributor_details h4 a',
      '.meta a'
    ]

    DESCRIPTION_MATCHES = [
      ['meta[@name="description"]', lambda { |el| el.attr('content') }],
      ['meta[@name="Description"]', lambda { |el| el.attr('content') }],
      ['meta[@name="DESCRIPTION"]', lambda { |el| el.attr('content') }],
      'rdf:Description[@name="dc:description"]',
      '.description'
    ]

    LEDE_MATCHES = [
      '.post-text p',
      '#blogpost p',
      '.story-teaser',
      '.article .body p',
      '//div[@class="entrytext"]//p[string-length()>40]',                      # Ruby Inside / Kubrick style
      'section p',
      '.entry .text p',
      '.hentry .content p',
      '.entry-content p',
      '#wikicontent p',                                                        # Google Code style
      '.wikistyle p',                                                          # GitHub style
      '//td[@class="storybody"]/p[string-length()>40]',                        # BBC News style
      '//div[@class="entry"]//p[string-length()>100]',
      # The below is a horrible, horrible way to pluck out lead paras from crappy Blogspot blogs that
      # don't use <p> tags..
      ['.entry-content', lambda { |el| el.inner_html[/(#{el.inner_text[0..4].strip}.*?)\<br/, 1] }],
      ['.entry', lambda { |el| el.inner_html[/(#{el.inner_text[0..4].strip}.*?)\<br/, 1] }],
      '.entry',
      '#content p',
      '#article p',
      '.post-body',
      '.entry-content',
      '.document_description_short p',    # Scribd
      '.single-post p'
    ]

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
      @all_titles ||= begin
        [ @doc.match(TITLE_MATCHES), html_title ].flatten.compact.uniq
      end
    end

    # Returns the title of the page/content - attempts to strip site name, etc, if possible
    def title
      titles.first
    end

    # HTML title
    def html_title
      @html_title ||= begin
        if title = @doc.match('title').first
          title
        else
          nil
        end
      end
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
