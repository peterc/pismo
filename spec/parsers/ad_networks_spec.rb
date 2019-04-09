RSpec.describe Pismo::Document do
  # This is working. We are building out AdChecker to have a fulller list,
  # then we'll set this up to check like we do for the authors
  # counter = 0
  each_fixture('./new_corpus/*.yml') do |file_path, file_name, data|
    # counter += 1
    # next if counter < 6

    def write_updated_fixture_with_results(location, hsh)
      write_fixture_file(location, hsh.to_yaml)
    end

    context file_path do
      let(:file_path) { file_path }
      let(:file_name) { file_name }

      context file_name do
        let(:hsh) { YAML.load(data) }
        let(:helper) { Pismo::Document.new(hsh[:body], url: hsh[:url]) }

        it 'author present' do
          puts "#{hsh[:url]}"
          helper.ad_networks
          binding.pry
        end
      end
    end
  end
end
