require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'open-uri'
require 'yaml'
require "mocha"

begin; require 'turn'; rescue LoadError; end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'pismo'

# Set time zone to prevent parsed times not matching those stored in metadata_expected.yaml
ENV['TZ'] = 'UTC'

class Test::Unit::TestCase
  include Pismo
  HTML_DIRECTORY = File.dirname(__FILE__) + "/corpus"
end