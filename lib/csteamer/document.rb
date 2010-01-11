require 'csteamer/internal_attributes'
require 'csteamer/external_attributes'

module CSteamer
  
  # CSteamer::Document represents a single HTML document within CSteamer
  class Document
    attr_reader :doc
    
    include CSteamer::InternalAttributes
    
    def initialize(handle)
      @html = if handle =~ /^http/
                open(handle).read
              elsif handle.is_a?(StringIO) || handle.is_a?(IO)
                handle.read
              else
                handle
              end
              
      @doc = Nokogiri::HTML(@html)
    end
    
    # An HTML representation of the document
    def html
      @doc.to_s
    end
  end
end