module Pismo
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
    # Returns the title of the page/content - attempts to strip site name, etc, if possible
    def title(all = false)
      # TODO: Memoizations
      title = @doc.match( 
                          [
                            '#pname a',                                                       # Google Code style
                            '.entryheader h1',                                                # Ruby Inside/Kubrick
                            '.entry-title a',                                               # Common Blogger/Blogspot rules
                            '.post-title a',
                            '.post_title a',
                            '.posttitle a',
                            '.post-header h1',
                            '.entry-title',
                            '.post-title',
                            '.post h1',
                            '.post h3 a',
                            'a.datitle',          # Slashdot style
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
                          ],
                          all
                        )
      
      # If all else fails, go to the HTML title
      if all
        return [html_title] if !title
        return ([*title] + [html_title]).uniq
      else
        return html_title if !title
        return title
      end
    end
    
    def titles
      title(true)
    end
    
    
    # HTML title
    def html_title
      title = @doc.match('title')
      return unless title
      title
    end
    
    # Return an estimate of when the page/content was created
    # As clients of this library should be doing HTTP retrieval themselves, they can fall to the
    # Last-Updated HTTP header if they so wish. This method is just rough and based on content only.
    def datetime
      # TODO: Clean all this mess up
      
      mo = %r{(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)\.?}i
      
      regexen = [
        /#{mo}\b\s+\d+\D{1,10}\d{4}/i,
        /(on\s+)?\d+\s+#{mo}\s+\D{1,10}\d+/i,
        /(on[^\d+]{1,10})\d+(th|st|rd)?.{1,10}#{mo}\b[^\d]{1,10}\d+/i,
        /\b\d{4}\-\d{2}\-\d{2}\b/i,
        /\d+(th|st|rd).{1,10}#{mo}\b[^\d]{1,10}\d+/i,
        /\d+\s+#{mo}\b[^\d]{1,10}\d+/i,
        /on\s+#{mo}\s+\d+/i,
        /#{mo}\s+\d+,? \d{4}+/i,
        /#{mo}\s+\d+/i,
        /\d{4}[\.\/\-]\d{2}[\.\/\-]\d{2}/,
        /\d{2}[\.\/\-]\d{2}[\.\/\-]\d{4}/
      ]
      
      datetime = 10
      
      regexen.each do |r|
        break if datetime = @doc.to_html[r]
      end
      
      return unless datetime && datetime.length > 4
      
      # Clean up the string for use by Chronic
      datetime.strip!
      datetime.gsub!(/(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)[^\w]*/i, '')
      datetime.gsub!(/(mon|tues|tue|weds|wed|thurs|thur|thu|fri|sat|sun)\.?[^\w]*/i, '')
      datetime.gsub!(/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\./i, '\1')
      datetime.sub!(/on\s+/, '')
      datetime.gsub!(/\,/, '')
      datetime.sub!(/(\d+)(th|st|rd)/, '\1')
      
      Chronic.parse(datetime) || datetime
    end
    
    # Returns the author of the page/content
    def author(all = false)
      author = @doc.match([
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
                          ], all)
                          
      return unless author
    
      # Strip off any "By [whoever]" section
      if String === author
        author.sub!(/^(post(ed)?\s)?by\W+/i, '')
        author.tr!('^a-zA-Z 0-9\'', '|')
        author = author.split(/\|{2,}/).first.to_s
        author.gsub!(/\s+/, ' ')
        author.gsub!(/\|/, '')
        author.strip!
      elsif Array === author
        author.map! { |a| a.sub(/^(post(ed)?\s)?by\W+/i, '') }.uniq!
      end
      
      author
    end
    
    def authors
      author(true)
    end
    
    
    # Returns the "description" of the page, usually comes from a meta tag
    def description
      @doc.match([
                  ['meta[@name="description"]', lambda { |el| el.attr('content') }],
                  ['meta[@name="Description"]', lambda { |el| el.attr('content') }],
                  ['meta[@name="DESCRIPTION"]', lambda { |el| el.attr('content') }],
                  'rdf:Description[@name="dc:description"]',
                  '.description'
       ])
    end
    
    # Returns the "lede(s)" or first paragraph(s) of the story/page
    def lede(all = false)
      lede = @doc.match([ 
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
                  ], all)

      # TODO: Improve sentence extraction - this is dire even if it "works for now"
      if lede && String === lede
        return (lede[/^(.*?[\.\!\?]\s){1,3}/m] || lede).to_s.strip
      elsif lede && Array === lede
        return lede.map { |l| l.to_s[/^(.*?[\.\!\?]\s){1,3}/m].strip || l }.uniq
      else
        return reader_doc && !reader_doc.sentences(4).empty? ? reader_doc.sentences(4).join(' ') : nil
      end
    end
    
    def ledes
      lede(true) rescue []
    end
    
    # Returns a string containing the first [limit] sentences as determined by the Reader algorithm
    def sentences(limit = 3)
      reader_doc && !reader_doc.sentences.empty? ? reader_doc.sentences(limit).join(' ') : nil
    end

    # Returns any images with absolute URLs in the document
    def images(limit = 3)
      reader_doc && !reader_doc.images.empty? ? reader_doc.images(limit) : nil
    end
    
    def relative_images(limit = 3)
      reader_doc && !reader_doc.relative_images.empty? ? reader_doc.relative_images(limit) : nil
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

    # Returns the "keywords" in the document (not the meta 'ss'keywords - they're next to useless now)
    def keywords(options = {})
      options = { :stem_at => 20, :word_length_limit => 15, :limit => 20, :remove_stopwords => true, :minimum_score => 2 }.merge(options)
      
      words = {}
      
      # Convert doc to lowercase, scrub out most HTML tags, then keep track of words
      cached_title = title.to_s
      content_to_use = body.to_s.downcase + " " + description.to_s.downcase

      # old regex for safe keeping -- \b[a-z][a-z\+\.\'\+\#\-]*\b
      content_to_use.downcase.gsub(/\<[^\>]{1,100}\>/, '').gsub(/\.+\s+/, ' ').gsub(/\&\w+\;/, '').scan(/(\b|\s|\A)([a-z0-9][a-z0-9\+\.\'\+\#\-\\]*)(\b|\s|\Z)/i).map{ |ta1| ta1[1] }.compact.each do |word|
        next if word.length > options[:word_length_limit]
        word.gsub!(/^[\']/, '')
        word.gsub!(/[\.\-\']$/, '')
        next if options[:hints] && !options[:hints].include?(word)
        words[word] ||= 0
        words[word] += (cached_title.downcase =~ /\b#{word}\b/ ? 5 : 1)
      end

      # Stem the words and stop words if necessary
      d = words.keys.uniq.map { |a| a.length > options[:stem_at] ? a.stem : a }
      s = Pismo.stopwords.map { |a| a.length > options[:stem_at] ? a.stem : a }

      words.delete_if { |k1, v1| v1 < options[:minimum_score] }
      words.delete_if { |k1, v1| s.include?(k1) } if options[:remove_stopwords]
      words.sort_by { |k2, v2| v2 }.reverse.first(options[:limit])
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
      url = @doc.match([['link[@rel="fluid-icon"]', lambda { |el| el.attr('href') }],      # Get a Fluid icon if possible..
                        ['link[@rel="shortcut icon"]', lambda { |el| el.attr('href') }],
                        ['link[@rel="icon"]', lambda { |el| el.attr('href') }]])
      if url && url !~ /^http/ && @url
        url = URI.join(@url , url).to_s
      end
      
      url
    end
    
    # Returns URL(s) of Web feed(s)
    def feed(all = false)
      url = @doc.match([['link[@type="application/rss+xml"]', lambda { |el| el.attr('href') }],
                        ['link[@type="application/atom+xml"]', lambda { |el| el.attr('href') }]], all
      )
      
      if url && String === url && url !~ /^http/ && @url
        url = URI.join(@url , url).to_s
      elsif url && Array === url
        url.map! do |u|
          if u !~ /^http/ && @url
            URI.join(@url, u).to_s
          else
            u
          end
        end
        url.uniq!
      end
      
      url
    end
    
    def feeds
      feed(true)
    end
  end
end
