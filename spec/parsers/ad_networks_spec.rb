# Authors Spec is commented out, because it does a full parsing, and this is
# is duplicate ot author_spec. So, based on that, we do a gut check of it
# on the authors spec for now.
# RSpec.describe Pismo::Document do
#   # This is working. We are building out AdChecker to have a fulller list,
#   # then we'll set this up to check like we do for the authors
#   # counter = 0
#   each_fixture('./new_corpus/*.yml') do |file_path, file_name, data|
#     # counter += 1
#     # next if counter < 6
# 
#     def write_updated_fixture_with_results(location, hsh)
#       write_fixture_file(location, hsh.to_yaml)
#     end
# 
#     # To keep from double parsing, we'll check that it doesn't raise an error
#     # on the authors spec, and not check this here.
#     xcontext file_path do
#       let(:file_path) { file_path }
#       let(:file_name) { file_name }
# 
#       context file_name do
#         let(:hsh) { YAML.load(data) }
#         let(:helper) { Pismo::Document.new(hsh[:body], url: hsh[:url]) }
# 
#         it 'author present' do
#           puts "#{hsh[:url]}"
#           helper.ad_networks
#         end
#       end
#     end
#   end
# end
