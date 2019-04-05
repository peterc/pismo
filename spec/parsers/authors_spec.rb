RSpec.describe Pismo::Document do
  each_fixture('./new_corpus/*.yml') do |file_name, data|
    next unless file_name.include?('user-deleted.livejournal.com')
    context file_name do
      let(:hsh) { YAML.load(data) }

      it 'author present' do
        start_time = Time.now
        puts "#{hsh[:url]}"
        helper =Pismo::Document.new(hsh[:body], url: hsh[:url])
        puts "Authors count: #{helper.authors.count}"
        fast_results = helper.authors
        puts "TOOK: #{Time.now - start_time}"
        helper.authors.each do |author|
          joined = %i[type identifier name username url uri image from].map do |key|
            "#{key}=#{author[key]}" if author[key].present?
          end.join("\t")
          puts joined
        end
        expect(helper.authors).to be_present
        # puts "SLOW"
        # helper = Pismo::Document.new(hsh[:body], url: hsh[:url], use_slow: true)
        # puts "Slow Authors count: #{helper.authors.count}"
        # slow_results = helper.authors
        # expect(helper.authors).to be_present
        # helper.authors.each do |author|
        #   joined = %i[type name url from].map do |key|
        #     "#{key}=#{author[key]}"
        #   end.join("\t")
        #   puts joined
        # end
        # fast_types = fast_results.map { |author| author[:type] }
        # slow_types = slow_results.map { |author| author[:type] }
        # fast_types_diff = fast_types -  slow_types
        # slow_types_diff = slow_types - fast_types
#
        # fast_names = fast_results.map { |author| author[:name] }
        # slow_names = slow_results.map { |author| author[:name] }
        # fast_names_diff = fast_names - slow_names
        # slow_names_diff = slow_names - fast_names
#
        # puts "\n\nDifferences between two systems"
        # puts "Count: fast=#{fast_results.count} slow=#{slow_results.count}"
        # puts "Types:"
        # puts "  in_fast_not_in_slow=#{fast_types_diff}"
        # puts "  in_slow_not_in_fast=#{slow_types_diff}"
        # puts "Names:"
        # puts "  in_fast_not_in_slow=#{fast_names_diff}"
        # puts "  in_slow_not_in_fast=#{slow_names_diff}\n\n"
      end
    end
  end
end
