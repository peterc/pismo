# Authors Spec is commented out, because it does a full parsing, and this is
# is duplicate to author_spec. So, based on that, we do a gut check of it
# on the authors spec for now.
RSpec.describe Pismo::Document do
  # This is working. We are building out AdChecker to have a fulller list,
  # then we'll set this up to check like we do for the authors
  # counter = 0
  each_fixture('./new_corpus/*.yml') do |file_path, file_name, data|
    # This counts the fixtures, and only runs 1 of these tests, as a gut
    # check. Remove to run all the author tests
    @counter = 0 if @counter.nil?
    @counter += 1
    next unless @counter == 1

    def write_updated_fixture_with_results(location, hsh)
      write_fixture_file(location, hsh.to_yaml)
    end

    # To keep from double parsing, we'll check that it doesn't raise an error
    # on the authors spec, and not check this here.
    context file_path do
      let(:file_path) { file_path }
      let(:file_name) { file_name }

      context file_name do
        let(:hsh) { YAML.load(data) }
        let(:helper) { Pismo::Document.new(hsh[:body], url: hsh[:url]) }

        it 'ad networks present' do
          expect(helper.ad_networks.length).to be > 0
        end
      end
    end
  end
end
