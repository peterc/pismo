
require 'helper'

class UtilitiesTest < Test::Unit::TestCase

  context "Pismo::Utilities " do

    should "find the longest repeated substring in a text" do

      a = ["Vaguely Related Posts (Usually)", "Factor's bootstrap process explained", "Factor: a practical stack language: Factor's bootstrap process explained"]
      result = Pismo::Utilities.longest_common_substring_in_array(a)
      assert_equal result, "Factor's bootstrap process explained"

    end

    should "pick the best title from an array" do
      site_name = "RubyInside"
      title = "CoffeeScript: A New Language With A Pure Ruby Compiler"

      a = [
        "#{site_name} - #{title}",
        "#{title}",
        "#{site_name}: #{title}"
      ]
      result = Pismo::Utilities.longest_common_substring_in_array(a)
      assert_equal result, title

    end

    should "return nil when array contains no common substrings" do
      a = ["CoffeeScript: A New Language With A Pure Ruby Compiler", "Vaguely Related Posts (Usually)"]
      result = Pismo::Utilities.longest_common_substring_in_array(a)
      assert_equal result, nil
    end

  end
end
