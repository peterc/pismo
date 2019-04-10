RSpec.describe "Fixes" do
  context "Peter Thiel document case" do
    let(:html) { load_from_fixture_folder('./peter_thiel.html') }
    let(:url)  { 'https://www.crunchbase.com/person/peter-thiel' }

    it 'works more quickly' do
      helper = Pismo::Document.new(url, html: html)
      helper.text
      binding.pry
    end
  end
end
