RSpec.describe 'feed parser' do
  it 'works' do
    file = load_from_fixture_folder('./corpus/factor.html')
    doc = Pismo::Document.new(file)
    expect(doc.feeds.length).to eq 3
  end
end
