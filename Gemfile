source "http://rubygems.org"

git_source(:omalab) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://omadeploy:git12345@github.com/#{repo_name}.git"
end
# Specify your gem's dependencies in pismo.gemspec

# This gem has text search additions to Nokogiri to find nodes that
# match text
gem 'nikkou',   omalab: 'omalab/nikkou'
gem 'allusion', path: '../allusion'
gem 'dewey',    path: '../dewey'

gemspec
