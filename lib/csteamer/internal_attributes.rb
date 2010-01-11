module CSteamer
  # Internal attributes are different pieces of data we can extract from a document's content
  module InternalAttributes
    # Returns the title of the page/content - attempts to strip site name, etc, if possible
    def title
      title = @doc.match('title')
      return unless title

      # Strip off any leading site names - a scrappy way to try it out..
      title.sub!(/^.{0,20}\s\-\s/, '')
      
      title
    end
    
    # Returns the author of the page/content
    def author
      author = @doc.match('.wire_author',      
                          ['meta[@name="author"]', lambda { |el| el.attr('content') }],     # Traditional meta tag style
                          '.byline a',                                                      # Ruby Inside style
                          '.post_subheader_left a',                                         # TechCrunch style
                          '.byl'                                                            # BBC News style
                          )
                          
      return unless author
    
      # Strip off any "By [whoever]" section
      author.sub!(/^by\s+/i, '')
      
      author
    end
    
    # Returns the "description" of the page, usually comes from a meta tag
    def description
      @doc.match( ['meta[@name="description"]', lambda { |el| el.attr('content') }],
                  ['meta[@name="Description"]', lambda { |el| el.attr('content') }]
       )
    end
    
    # Returns the "lede" or first paragraph of the story/page
    def lede
      @doc.match( '//div[@class="entrytext"]//p[string-length()>10]',
                  'section p',
                  '//td[@class="storybody"]/p[string-length()>10]'                         # BBC News style
                  )
    end
  end
end