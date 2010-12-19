# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'chronic'
require 'sanitize'
require 'tempfile'

$: << File.dirname(__FILE__)
require 'pismo/document'
require 'pismo/reader'

if RUBY_PLATFORM == "java"
  class String; def stem; self; end; end
else
  require 'fast_stemmer'
end

module Pismo
  # Sugar methods to make creating document objects nicer
  def self.document(handle, url = nil)
    Document.new(handle, url)
  end
  
  # Load a URL, as with Pismo['http://www.rubyinside.com'], and caches the Pismo document
  # (mostly useful for debugging use)
  def self.[](url)
    @docs ||= {}
    @docs[url] ||= Pismo::Document.new(url)
  end
  
  
  # Return stopword list
  def self.stopwords
    @stopwords ||= File.read(File.dirname(__FILE__) + '/pismo/stopwords.txt').split rescue []
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
  
  def match(queries = [], all = false)
    r = [] if all
    [*queries].each do |query|
      if query.is_a?(String)
        if el = self.search(query).first
          if el.name.downcase == "meta"
            result = el['content'].strip rescue nil
          else
            result = el.inner_text.strip rescue nil
          end
        end
      elsif query.is_a?(Array)
        result = query[1].call(self.search(query.first).first).strip rescue nil
      end

      if result
        # TODO: Sort out sanitization in a more centralized way
        result.gsub!('’', '\'')
        result.gsub!('—', '-')
        if all
          r << result
        else
          return result
        end
      end
    end
    all && !r.empty? ? r : nil
  end
end