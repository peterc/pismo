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
    attr_reader :doc, :url, :args

    ATTRIBUTE_METHODS = InternalAttributes.instance_methods + ExternalAttributes.instance_methods

    include Pismo::PageAttributes
    include Pismo::InternalAttributes
    include Pismo::ExternalAttributes
    include Pismo::NlpAttributes
    include Pismo::TwitterTextAttributes
    include Pismo::SchemaAttributes

    def initialize(handle, args = {})
      @args = {}
      @args = handle if handle.is_a?(Hash)
      @args = @args.merge(args)
      @args[:handle] = handle unless handle.is_a?(Hash)
      true
    end

    def html
      @html ||= begin
        html = args.dig(:handle, :html) if args.dig(:handle).is_a?(Hash)
        html = args.dig(:document)      if html.nil?
        html = args.dig(:html)          if html.nil?
        html = handle.read              if file_readers.any? { |kind| handle.is_a?(kind) }
        html = args.dig(:handle)        if args.dig(:handle).is_a?(String) && args.dig(:handle).include?("<body")
        html
      end
    end

    def handle
      @handle ||= args.dig(:handle)
    end

    def url
      @url ||= begin
        url = args.dig(:url)
        url = args.dig(:handle) if args.dig(:handle).is_a?(String) && args.dig(:handle) =~ /\Ahttp/i
        url
      end
    end

    def file_readers
      [IO, Tempfile]
    end

    def doc
      @doc ||= Nokogiri::HTML(html, nil, 'UTF-8') if html.present?
    end

    def headers
      @headers ||= args.dig(:headers) || {}
    end

    def match(args = [], all = false)
      doc.match([*args], all)
    end

    private

    def handle
      @handle ||= args.dig(:handle)
    end
  end
end
