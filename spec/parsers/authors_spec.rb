RSpec.describe Pismo::Document do
  each_fixture('./new_corpus/*.yml') do |file_name, data|
    context file_name do
      let(:hsh) { YAML.load(data) }
      let(:helper) { Pismo::Document.new(hsh[:body], url: hsh[:url]) }

      it 'author present' do
        puts "    #{hsh[:url]}"
        expect(helper.authors).to be_present
        puts "    #{helper.authors.count} authors found"
        puts "    #{helper.authors.inspect}"
        binding.pry
      end
    end
  end
end
