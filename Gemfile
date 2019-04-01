source "http://rubygems.org"

git_source(:omalab) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://omadeploy:git12345@github.com/#{repo_name}.git"
end

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'engtagger',                  github: 'omalab/engtagger'
gem 'confidential_info_redactor', github: 'omalab/confidential_info_redactor'
gem 'rwordnet',                   github: 'vladkostyuk/rwordnet'

# Specify your gem's dependencies in pismo.gemspec

# This gem has text search additions to Nokogiri to find nodes that
# match text ( i dont think this is needed anymore )
gem 'nikkou',   omalab: 'omalab/nikkou'

# Other gems, they are needed
gem 'allusion', omalab: 'allusion'     # path: '../allusion'
gem 'dewey',    omalab: 'dewey'        # path: '../dewey'

gemspec
