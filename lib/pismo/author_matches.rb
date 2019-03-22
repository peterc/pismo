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
  '.node-byline',                                                   # FastCompany
  '.post_subheader_left a',                                         # TechCrunch style
  '.byl',                                                           # BBC News style
  '.articledata .author a',
  '#owners a',                                                      # Google Code style
  '.author a',
  '.author',
  '.auth a',
  '.auth',
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
