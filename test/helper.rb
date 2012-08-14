require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'open-uri'
require 'yaml'
begin; require 'turn'; rescue LoadError; end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'pismo'

# Set time zone to prevent time interpretations not matching thoes stored in metadata_expected.yaml
ENV['TZ'] = 'UTC'

class Test::Unit::TestCase
  include Pismo
  HTML_DIRECTORY = File.dirname(__FILE__) + "/corpus"
end