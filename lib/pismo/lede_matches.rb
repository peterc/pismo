LEDE_MATCHES = [
  '.post-text p',
  '#blogpost p',
  '.story-teaser',
  '.article .body p',
  '//div[@class="entrytext"]//p[string-length()>40]',                      # Ruby Inside / Kubrick style
  'section p:not(.advertisement,.advertisement_river)',
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
  '#content p:not(.advertisement,.advertisement_river)',
  '#article p',
  '.post-body',
  '.entry-content',
  '.document_description_short p',    # Scribd
  '.single-post p'
]
