# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'chronic'
require 'sanitize'
require 'tempfile'
require 'phrasie'
require 'twitter-text'
require 'htmlentities'
require 'allusion'

$: << File.dirname(__FILE__)
require 'pismo/document'
require 'pismo/reader'
require 'pismo/reader/base'
require 'pismo/reader/tree'
require 'pismo/reader/cluster'
require 'pismo/images/image_extractor'
require 'pismo/utilities'

# Additional parsing types
require 'pismo/parsers/base'
require 'pismo/parsers/twitter_text'
require 'pismo/parsers/jsonld'
require 'pismo/parsers/meta'
require 'pismo/parsers/authors/html'
require 'pismo/parsers/authors/meta_author'
require 'pismo/parsers/authors/twitter'
require 'pismo/parsers/author'
require 'pismo/parsers/published_date'
require 'pismo/parsers/ad_networks'

if RUBY_PLATFORM == "java"
  class String; def stem; self; end; end
else
  require 'fast_stemmer'
end

module Pismo
  class << self
    # The root of the blackbook. Loaded first to enable us to set paths in
    # loaded modules relative to the root of blackbook itself
    def root
      File.expand_path(File.join(File.dirname(__FILE__), '..'))
    end

    # Sugar methods to make creating document objects nicer
    def document(handle, options = {})
      Document.new(handle, options)
    end

    # Load a URL, as with Pismo['http://www.rubyinside.com'], and caches the Pismo document
    # (mostly useful for debugging use)
    def [](url)
      @docs ||= {}
      @docs[url] ||= Pismo::Document.new(url)
    end

    def normalize_entities(text)
      @entities ||= HTMLEntities.new
      normalize_unicode_characters @entities.decode(text)
    end
  end

  UNICODE_CONVERSIONS = {
    "8230" => '...',
    "8194" => ' ',
    "8195" => ' ',
    "8201" => ' ',
    "8211" => '-',
    "8216" => '\'',
    "8217" => '\'',
    "8220" => '"',
    "8221" => '"'
  }
  TRANSLATED_CONVERSIONS = UNICODE_CONVERSIONS.map {|k, v| [k.to_i.chr("UTF-8"), v] }

  def self.normalize_unicode_characters(html)
    TRANSLATED_CONVERSIONS.each {|k,v| html.gsub! k, v }
    html
  end

  class NFunctions
    def self.match_href(list, expression)
      list.find_all { |node| node['href'] =~ /#{expression}/ }
    end
  end
end

# Add some sugar to Nokogiri
class Nokogiri::HTML::Document
  def get_the(search)
    self.search(search).first rescue nil
  end

  def match(queries = [])
    [].tap do |results|
      [*queries].each do |query|
        result = begin
          if query.is_a?(String)
            if el = self.search(query).first
              if el.name.downcase == "meta"
                el['content']
              else
                el.inner_text
              end
            end
          elsif query.is_a?(Array)
            self.search(query.first).map do |node|
              query.last.call(node)
            end
          end
        rescue
          nil
        end
        Array(result).compact.each do |r|
          results << Pismo.normalize_entities(r.strip)
        end
      end
    end.compact
  end
end
