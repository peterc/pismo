# pismo (Web page content analyzer and metadata extractor)

* http://github.com/peterc/pismo

## DESCRIPTION:

Pismo extracts metadata and machine-usable data from mostly unstructured (or poorly structured)
HTML documents. These data include titles, feed URLs, ledes, body text, graphics, date, and keywords.

For example, if you have a blog post HTML file, Pismo, in theory, should
extract the title, the actual "content", and analyze for keywords, among other things.

Pismo only understands (and much prefers) English. Je suis desolé.

## EXAMPLES:

    require 'pismo'
    
    # Load a Web page (you can pass an IO object or a string with existing HTML data along too, if you prefer)
    doc = Pismo::Document.new('http://www.rubyinside.com/cramp-asychronous-event-driven-ruby-web-app-framework-2928.html')
    
    doc.title     # => "Cramp: Asychronous Event-Driven Ruby Web App Framework"
    doc.author    # => "Peter Cooper"
    doc.lede      # => "Cramp (GitHub repo)is a new, asynchronous evented Web app framework by Pratik Naik of 37signals (and the Rails core team). It's built around Ruby's EventMachine library and was designed to use event-driven I/O throughout - making it ideal for situations where you need to handle a large number of open connections (such as Comet systems or streaming APIs.)"
    doc.keywords  # => [["cramp", 7], ["controllers", 3], ["app", 3], ["basic", 2], ..., ... ]
    
## STATUS:

Pismo is a work in progress and is being used heavily in the development of http://coder.io/. Pismo is used in production systems on both Ruby 1.8 and 1.9. I do not know how it fares on JRuby, Rubinius, or others yet.    

## NEW IN 0.5.0:

### Stopword access

You can now access Pismo's stopword list directly:

    Pismo.stopwords    # => [.., .., ..]  
    
### Convenience access method for IRB/debugging use

Now you can get playing with Pismo faster. This is primarily useful for debugging/playing in IRB as it just uses open-uri and the Pismo document is cached in the class against the URL:

    url = "http://www.rubyinside.com/the-why-what-and-how-of-rubinius-1-0-s-release-3261.html"
    Pismo[url].title   # => "The Why, What, and How of Rubinius 1.0's Release"
    Pismo[url].author  # => "Peter Cooper"

### Arrays of all matches for titles, ledes, authors, and feeds

Pismo is not perfect and you might like to instead see all of the potential titles/ledes/authors or feeds that Pismo can find. You can now do this and judge them by your metrics.

    doc.titles    # => [..., ..., ...]    
    doc.ledes    # => [..., ..., ...]    
    doc.authors    # => [..., ..., ...]    
    doc.feeds    # => [..., ..., ...]
    
## COMMAND LINE TOOL:

A command line tool called "pismo" is included so that you can get metadata about a page from the command line. This is
great for testing, or perhaps calling it from a non Ruby script. The output is currently in YAML.

### Usage: 

    ./bin/pismo http://www.rubyinside.com/cramp-asychronous-event-driven-ruby-web-app-framework-2928.html title lede author datetime
    
### Output:

    --- 
    :url: http://www.rubyinside.com/cramp-asychronous-event-driven-ruby-web-app-framework-2928.html
    :title: "Cramp: Asychronous Event-Driven Ruby Web App Framework"
    :lede: Cramp (GitHub repo)is a new, asynchronous evented Web app framework by Pratik Naik of 37signals
    :author: Peter Cooper
    :datetime: 2010-01-07 12:00:00 +00:00

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history as it's handled by Jeweler (which is awesome, btw).
* Send me a pull request. I may or may not accept it (sorry, practicality rules.. but message me and we can talk!)

## COPYRIGHT AND LICENSE

Apache 2.0 License - See LICENSE for details.

All except lib/pismo/readability.rb is Copyright (c) 2009, 2010 Peter Cooper
lib/pismo/readability.rb is Copyright (c) 2009, 2010 Arc90 Inc, starrhorne, and iterationlabs

The readability stuff was ganked from http://github.com/iterationlabs/ruby-readability - sorry! I have respected the license, however. I have promised to contribute back to them directly and, hopefully, use that library as a regular dependency. But.. this takes time.