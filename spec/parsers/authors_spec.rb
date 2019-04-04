RSpec.describe Pismo::Document do
  each_fixture('./new_corpus/*.yml') do |file_name, data|
    context file_name do
      let(:hsh) { YAML.load(data) }
      let(:helper) { Pismo::Document.new(hsh[:body], url: hsh[:url]) }

      it 'author present' do
        puts "    #{hsh[:url]}"
        expect(helper.authors).to be_present
        puts "    WARN: Publisher Only - #{hsh[:url]}"  if helper.authors.length == 1 and helper.authors.first[:type] == 'publisher/profile'
      end
    end
  end
end
