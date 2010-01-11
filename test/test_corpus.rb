require 'helper'

class TestCorpus < Test::Unit::TestCase
    
  context "A corpus of HTML documents" do
    setup do
      # Load the corpus files' HTML content into a hash
      @corpus = {}
      Dir[HTML_DIRECTORY + "/*.html"].each { |filename| @corpus[File.basename(filename).sub(/\.html$/, '').to_sym] = File.read(filename) }
      
      # Load the "expected metadata" ready for tests
      @metadata = YAML.load(open(HTML_DIRECTORY + "/metadata_expected.yaml"))      
    end
    
    should "pass basic sanitization and result in Nokogiri documents" do
      @corpus.values.each do |html|
        doc = Document.new(html)
        doc.html.length.should > 1000
        doc.doc.kind_of?(Nokogiri::HTML::Document).should == true
      end
    end
    
    should "pass metadata extraction tests" do
      
      @metadata.each do |file, expected|
        @doc = Document.new(@corpus[file])
        expected.each do |k, v|
          @doc.send(k).should == v
        end
      end
    end
  end
end
