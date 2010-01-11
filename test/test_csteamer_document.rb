require 'helper'

class TestCSteamerDocument < Test::Unit::TestCase
  context "CSteamer::Document" do
    should "process an IO/File object" do
      doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
      doc.doc.kind_of?(Nokogiri::HTML::Document).should == true
    end
  end
  
  context "A very basic CSteamer document" do
    setup do
      @doc = Document.new(%{<html><body><h1>Hello</h1></body></html>})
    end
    
    should "pass sanitization" do
      @doc.html.should == %{<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">\n<html><body><h1>Hello</h1></body></html>\n}
    end
    
    should "result in a Nokogiri document" do
      @doc.doc.kind_of?(Nokogiri::HTML::Document).should == true
    end
  end
  
  context "A basic real world blog post" do
    setup do
      @doc = Document.new(open(HTML_DIRECTORY + "/rubyinside.html"))
    end
    
    should "provide a title" do
      @doc.title.should == "CoffeeScript: A New Language With A Pure Ruby Compiler"
    end
  end
end
