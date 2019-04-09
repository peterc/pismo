source "http://rubygems.org"

git_source(:omalab) { |repo_name| "https://omadeploy:git12345@github.com/omalab/#{repo_name}" }
git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'engtagger',                  omalab: 'engtagger'
gem 'confidential_info_redactor', omalab: 'confidential_info_redactor'
gem 'rwordnet',                   github: 'vladkostyuk/rwordnet'

# Specify your gem's dependencies in pismo.gemspec

# This gem has text search additions to Nokogiri to find nodes that
# match text ( i dont think this is needed anymore )
gem 'nikkou',   omalab: 'nikkou'

# Other gems, they are needed
gem 'mida',       omalab: 'mida'         # path: '../mida'
gem 'allusion',   omalab: 'allusion'     # path: '../allusion'
#gem 'dewey',      omalab: 'dewey'        # path: '../dewey'
gem 'dewey',      path: '../dewey'
gem 'ad_checker', omalab: 'ad_checker'

gemspec
