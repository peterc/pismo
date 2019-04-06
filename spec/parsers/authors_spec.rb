RSpec.describe Pismo::Document do
  each_fixture('./new_corpus/*.yml') do |file_path, file_name, data|
    def write_updated_fixture_with_results(location, hsh)
      write_fixture_file(location, hsh.to_yaml)
    end

    def print_authors(helper)
      helper.authors.each do |author|
        joined = %i[type identifier name username url uri image from].map do |key|
          "#{key}=#{author[key]}" if author[key].present?
        end.join("  ")
        puts joined
      end
    end

    def print_authors_status(helper)
      helper.authors.each do |author|
        joined = []
        joined << "type=#{author[:type]}"
        joined = %i[ name url image ].map do |key|
          joined << "#{key}=false" if author[key].blank?
        end
        puts joined.join(' ')
      end
    end

    context file_path do
      let(:file_path) { file_path }
      let(:file_name) { file_name }

      context file_name do
        let(:hsh) { YAML.load(data) }

        it 'author present' do
          start_time = Time.now
          puts "    #{hsh[:url]}"
          helper = Pismo::Document.new(hsh[:body], url: hsh[:url])

          expect do
            start_time = Time.now
            helper.authors
            puts "    WARN: took=#{Time.now - start_time}" if Time.now - start_time > 10.00
          end.to_not raise_error

          print_authors(helper)
          expect_to_have_at_least_one_author(helper)

          # When the results are right, then we write them back to the hsh
          # so we can check that we're still getting good results in the future
          # if hsh.key?(:results)
          expect_to_find_the_same_author_results(helper, hsh)
          # else
            # hsh[:results] = helper.authors
            # write_updated_fixture_with_results(file_path, hsh)
          # end
        end
      end
    end
  end
end
