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
