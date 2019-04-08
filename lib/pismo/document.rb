# encoding: utf-8
require 'pismo/page_attributes'
require 'pismo/internal_attributes'
require 'pismo/external_attributes'
require 'pismo/nlp_attributes'
require 'pismo/twitter_text_attributes'
require 'pismo/schema_attributes'

module Pismo

  # Pismo::Document represents a single HTML document within Pismo
  class Document
    attr_reader :doc, :url, :options

    ATTRIBUTE_METHODS = InternalAttributes.instance_methods + ExternalAttributes.instance_methods
    DEFAULT_OPTIONS = {
      :image_extractor  => false,
      :min_image_width  => 100,
      :min_image_height => 100
    }

    include Pismo::PageAttributes
    include Pismo::InternalAttributes
    include Pismo::ExternalAttributes
    include Pismo::NlpAttributes
    include Pismo::TwitterTextAttributes
    include Pismo::SchemaAttributes

    def initialize(handle, options = {})
      @options = DEFAULT_OPTIONS.merge options
      url = @options.delete(:url)
      load(handle, url)
    end

    # An HTML representation of the document
    def html
      @doc.to_s
    end

    def headers
      @headers ||= @options.dig(:headers) || {}
    end

    def load(handle, url = nil)
      url = handle.dig(:url) if handle.is_a?(Hash) && url.nil?
      html = handle.dig(:html) if handle.is_a?(Hash)
      @url = url if url
      @url = handle if handle =~ /\Ahttp/i

      @html = if html.present?
                html
              elsif handle =~ /\Ahttp/i
                open(handle) { |f| f.read }
              elsif handle.is_a?(StringIO) || handle.is_a?(IO) || handle.is_a?(Tempfile)
                handle.read
              else
                handle
              end

      @doc = Nokogiri::HTML(@html)
    end

    def match(args = [], all = false)
      @doc.match([*args], all)
    end
  end
end
