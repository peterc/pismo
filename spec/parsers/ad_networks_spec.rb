RSpec.describe Pismo::Document do
  each_fixture('./new_corpus/*.yml') do |file_path, file_name, data|
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
          # binding.pry
        end
      end
    end
  end
end
