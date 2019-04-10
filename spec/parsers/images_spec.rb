RSpec.describe Pismo::Document do
  it 'extracts images' do
    file_path, file_name, hsh = get_yaml_fixture('./new_corpus/anovaculinary.com_1.yml')
    helper = Pismo::Document.new(hsh[:body], url: hsh[:url])
    expect(helper.images.length).to be > 0
  end
end
