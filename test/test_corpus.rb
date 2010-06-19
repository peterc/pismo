require 'helper'

class TestCorpus < Test::Unit::TestCase
    
  context "A corpus of HTML documents" do
    setup do
      # Load the corpus files' HTML content into a hash
      @corpus = {}
      Dir[HTML_DIRECTORY + "/*.html"].each { |filename| @corpus[File.basename(filename).sub(/\.html$/, '').to_sym] = File.read(filename) }
      
      # Load the "expected metadata" ready for tests
      @metadata = YAML.load(open(HTML_DIRECTORY + "/metadata_expected.yaml"))
      @reader_metadata = YAML.load(open(HTML_DIRECTORY + "/reader_expected.yaml"))
    end
    
    should "pass basic sanitization and result in Nokogiri documents" do
      @corpus.values.each do |html|
        doc = Document.new(html)
        assert doc.html.length > 1000
        assert doc.doc.kind_of?(Nokogiri::HTML::Document)
      end
    end
    
    should "pass metadata extraction tests" do
      
      @metadata.each do |file, expected|
        @doc = Document.new(@corpus[file])
        expected.each do |k, v|
          assert_equal v, @doc.send(k)
        end
      end
    end
    
    should "pass content extraction tests" do
      @reader_metadata.each do |file, expected|
        @doc = Reader::Document.new(@corpus[file])
        assert_equal expected, @doc.sentences(2)
      end
    end    
  end
end
