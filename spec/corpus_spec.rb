RSpec.describe 'Corpus' do
  context 'basic sanity check on Nokogiri object parsing' do
    yield_files_in_fixtures_folder('./corpus/*.html') do |full_path, name, html|
      it "#{name}" do
        doc = Pismo::Document.new(html)
        expect(doc.html.length).to be > 1000
        expect(doc.doc).to be_a_kind_of(Nokogiri::HTML::Document)
      end
    end
  end
end
