RSpec.describe Pismo::Document do
  each_fixture('./new_corpus/*.yml') do |file_name, data|
    context file_name do
      let(:hsh) { YAML.load(data) }

      it 'author present' do
        puts "#{hsh[:url]}"
        puts "FAST"
        helper =Pismo::Document.new(hsh[:body], url: hsh[:url], use_fast: true)
        puts "Fast Authors count: #{helper.authors.count}"
        helper.authors.each do |author|
          joined = author.keys.map do |key|
            "#{key}=#{author[key]}"
          end.join (' ')
          puts joined
        end
        expect(helper.authors).to be_present
        puts "SLOW"
        helper = Pismo::Document.new(hsh[:body], url: hsh[:url], use_slow: true)
        puts "Slow Authors count: #{helper.authors.count}"
        expect(helper.authors).to be_present
        helper.authors.each do |author|
          joined = author.keys.map do |key|
            "#{key}=#{author[key]}"
          end.join (' ')
          puts joined
        end
      end
    end
  end
end
