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
require 'dewey'
require 'public_suffix'
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
require 'pismo/parsers/titles'
require 'pismo/parsers/descriptions'
require 'pismo/parsers/ledes'
require 'pismo/parsers/twitter_text'
require 'pismo/parsers/jsonld'
require 'pismo/parsers/meta'
require 'pismo/parsers/authorship'
require 'pismo/parsers/authors'
require 'pismo/parsers/published_date'
require 'pismo/parsers/ad_networks'
require 'pismo/parsers/feeds'
require 'pismo/parsers/favicons'
require 'pismo/parsers/keywords'
require 'pismo/parsers/links'
require 'pismo/parsers/tags'

require 'pismo/utils/indicators'
require 'pismo/utils/hash_search'
require 'pismo/utils/url'
require 'pismo/utils/nodes_to_profiles'
require 'pismo/utils/search_for_additional_profiles'
require 'pismo/utils/convert_to_plain_text'
require 'pismo/utils/log_tracker'

if RUBY_PLATFORM == "java"
  class String; def stem; self; end; end
else
  require 'fast_stemmer'
end

# Pismo is the main parser
module Pismo
  class << self
    # The root of the gem. Loaded first to enable us to set paths in
    # loaded modules relative to the root of the gem itself
    def root
      File.expand_path(File.join(File.dirname(__FILE__), '../..'))
    end

    # Use the logger, and this can be overwritten by a custom logger
    # Blackbook.logger.info 'some info'
    def logger
      @logger ||= ::Logger.new($stdout).tap do |log|
        log.progname = self.name
      end
    end

    # You san set the logger to be whatever you want, by using this
    # method. Then, you are in control of whatever its settings are.
    def logger=(logging_system)
      @logger = logging_system
    end

    # The tracker lets you put StatsD-like messages into the code base
    # If you put a statsd client here, it will respect the UI like
    # https://www.rubydoc.info/github/github/statsd-ruby/Statsd
    #
    # If you do nothign, then it will simply log into in a common way
    # to the Pismo Logger.
    def tracker
      @tracker ||= Pismo::Utils::LogTracker.new
    end

    # You can override the LogTracker and add StatsD. You'd do this in
    # production. You control all the options. It requires an interface
    # that looks like
    # https://www.rubydoc.info/github/github/statsd-ruby/Statsd
    def tracker=(stats_system)
      @tracker = stats_system
    end

    # Dev logger lets you put in logging that won't show in production
    # without having to deal with commenting and uncommenting it
    def dev_logger(str, level = 'info')
      Pismo.logger.send(level, str) if dev_logging?
    end

    # Checks for a DEV_LOGGING = true ENV variable, so we know if we need
    # to do logging
    def dev_logging?
      @dev_logging ||= ENV.fetch('DEV_LOGGING', 'false').to_s == 'true'
    end

    # Reads the config from the YAML file

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
