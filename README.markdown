# pismo - Web page content analysis and metadata extraction

## DESCRIPTION:

Pismo extracts machine-usable metadata from unstructured (or poorly structured) English-language HTML documents. Data that Pismo can extract include titles, feed URLs, ledes, body text, image URLs, date, and keywords.

All tests pass on Ruby 1.9.3 and 2.0.0. Currently fails on JRuby 1.7.2 due to dependencies.

## NEWS:

April 4, 2019: Welcome back from the dead. We've dramatically rewritten this from the ground up for the modern age.

March 25, 2013: Version 0.8.0 is now the edge version (but not released as a gem yet). It may be incompatible with earlier releases as it has a LOT of commits and changes made by other people which have not yet been fully tested or audited. Install gem for 0.7.4 if you wish to remain on the 'stable' version for now.

February 27, 2013: Version 0.7.4 has been released to ensure Ruby 2.0.0 compatibility but significant pull requests remain yet to be merged and handled.

December 19, 2010: Version 0.7.2 has been released - it includes a patch from Darcy Laycock to fix keyword extraction problems on some pages, has switched from Jeweler to Bundler for management of the gem, and adds support for JRuby 1.5.6 by skipping stemming on that platform.

## USAGE:

A basic example of extracting basic metadata from a Web page:

    require 'pismo'

    # Load a Web page (you could pass an IO object or a string with existing HTML data along, as you prefer)
    doc = Pismo::Document.new('http://www.rubyinside.com/cramp-asychronous-event-driven-ruby-web-app-framework-2928.html')

    doc.title     # => "Cramp: Asychronous Event-Driven Ruby Web App Framework"
    doc.author    # => "Peter Cooper"
    doc.lede      # => "Cramp (GitHub repo) is a new, asynchronous evented Web app framework by Pratik Naik of 37signals (and the Rails core team). It's built around Ruby's EventMachine library and was designed to use event-driven I/O throughout - making it ideal for situations where you need to handle a large number of open connections (such as Comet systems or streaming APIs.)"
    doc.keywords  # => [["cramp", 7], ["controllers", 3], ["app", 3], ["basic", 2], ..., ... ]

There's also a shorter "convenience" method which might be handy in IRB - it does the same as Pismo::Document.new:

    Pismo['http://www.rubyflow.com/items/4082'].title   # => "Install Ruby as a non-root User"

The current metadata methods are:

* title
* titles
* author
* authors
* lede
* keywords
* sentences(qty)
* body
* html_body
* feed
* feeds
* favicon
* description
* datetime

These methods are not fully documented here yet - you'll just need to try them out. The plural methods like #titles, #authors, and #feeds will return multiple matches in an array, if present. This is so you can use your own techniques to choose a "best" result in ambiguous cases.

The html_body and body methods will be of particular interest. They return the "body" of the page as determined by Pismo's "Reader". #body returns it as plain-text, #html_body maintains some basic HTML styling.

The default reader is the "tree" reader. This works in a similar fashion to Arc90's Readability or Safari Reader algorithm.


## CAVEATS AND SHORTCOMINGS:

There are some shortcomings or problems that I'm aware of and am going to pursue:

* I do not know how Pismo fares on Rubinius
* pismo requires Bundler - get it :-)
* pismo does not install on JRuby due to a problem in the fast-stemmer dependency
* Some users have had issues with using Pismo from irb. This appears to be related to Nokogiri use causing a segfault
* The "Reader" content extraction algorithm is not perfect. It can sometimes return crap and can barf on certain types of characters for sentence extraction
* The author name extraction isn't very strong and is best avoided for now
* The image extraction only deals with images with absolute URLs (optional; pass `:all_images => true` to `Pismo::Document.new` to include relative images)
* The corpus in test/corpus needs significantly extending

## OTHER GROOVY STUFF:

### Command Line Tool

A command line tool called "pismo" is included so that you can get metadata about a page from the command line. This is
great for testing, or perhaps calling it from a non Ruby script. The output is currently in YAML.

#### Usage:

    ./bin/pismo http://www.rubyinside.com/cramp-asychronous-event-driven-ruby-web-app-framework-2928.html title lede author datetime

#### Output:

    ---
    :url: http://www.rubyinside.com/cramp-asychronous-event-driven-ruby-web-app-framework-2928.html
    :title: "Cramp: Asychronous Event-Driven Ruby Web App Framework"
    :lede: Cramp (GitHub repo)is a new, asynchronous evented Web app framework by Pratik Naik of 37signals
    :author: Peter Cooper
    :datetime: 2010-01-07 12:00:00 +00:00

If you call pismo without any arguments (except a URL), it starts an IRB session so you can directly work in Ruby. The URL provided is loaded
and assigned to both the constant 'P' and the variable @p.

### Alternate readers

Pismo supports different readers for extracting the #body and #html_body from the web page.

The "cluster" reader uses an algorithm that tries to cluster contiguous content blocks together to identify the main document body.  This is based on the ExtractContent gem (http://rubyforge.org/projects/extractcontent/).

The reader can be specified as part of #Document.new :

    doc = Document.new(url, :reader => :cluster)


## Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history as it's handled by Jeweler (which is awesome, btw).
* Send me a pull request. I may or may not accept it (sorry, practicality rules.. but message me and we can talk!)

## COPYRIGHT AND LICENSE

Apache 2.0 License - See LICENSE for details.
Copyright (c) 2009, 2010, 2013 Peter Cooper et al.

In short, you can use Pismo for whatever you like commercial or not, but please include a brief credit (as in the NOTICE file - as per the Apache 2.0 License) somewhere deep in your license file or similar, and, if you're nice and have the time, let me know if you're using it and/or share any significant changes or improvements you make.

http://github.com/peterc/pismo
