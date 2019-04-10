RSpec.describe "Fixes" do
  context "Peter Thiel document case" do
    let(:html) { load_from_fixture_folder('./peter_thiel.html') }
    let(:url)  { 'https://www.crunchbase.com/person/peter-thiel' }

    it 'does not have tokens jammed together' do
      helper = Pismo::Document.new(url, html: html)
      helper.text
      expect(helper.text).to_not include "foundedPal"
    end
  end
end
