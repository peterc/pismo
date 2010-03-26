require 'pismo/internal_attributes'
require 'pismo/external_attributes'

module Pismo
  
  # Pismo::Document represents a single HTML document within Pismo
  class Document
    attr_reader :doc, :url
    
    ATTRIBUTE_METHODS = InternalAttributes.instance_methods + ExternalAttributes.instance_methods
    
    include Pismo::InternalAttributes
    include Pismo::ExternalAttributes
    
    def initialize(handle, url = nil)
      load(handle, url)
    end
    
    # An HTML representation of the document
    def html
      @doc.to_s
    end
    
    def load(handle, url = nil)
      @url = url if url
      @url = handle if handle =~ /^http/
      
      @html = if handle =~ /^http/
                open(handle).read
              elsif handle.is_a?(StringIO) || handle.is_a?(IO)
                handle.read
              else
                handle
              end
              
      @html = clean_html(@html)
      
      @doc = Nokogiri::HTML(@html)
    end
    
    def clean_html(html)
      html.gsub!('&#8217;', '\'')
      html.gsub!('&#8221;', '"')
      html.gsub!('&#8211;', '-')
      html.gsub!('&#8220;', '"')
      html.gsub!('&nbsp;', ' ')
      html
    end
  end
end