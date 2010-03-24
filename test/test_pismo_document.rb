require 'helper'

class TestPismoDocument < Test::Unit::TestCase
  context "Pismo::Document" do
    should "process an IO/File object" do
      doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
      assert doc.doc.kind_of?(Nokogiri::HTML::Document)
    end
  end
  
  context "A very basic Pismo document" do
    setup do
      @doc = Document.new(%{<html><body><h1>Hello</h1></body></html>})
    end
    
    should "pass sanitization" do
      assert_equal %{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">\n<html><body><h1>Hello</h1></body></html>\n}, @doc.html
    end
    
    should "result in a Nokogiri document" do
      assert @doc.doc.kind_of?(Nokogiri::HTML::Document)
    end
  end
  
  context "A basic real world blog post" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
    end
    
    should "provide a title" do
      assert_equal  "CoffeeScript: A New Language With A Pure Ruby Compiler", @doc.title
    end
  end
end
