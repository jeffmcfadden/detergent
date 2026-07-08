# Detergent

Detergent scrubs junk out of web pages. Give it an HTML document and it removes ads, navigation, scripts, sidebars, and other cruft, then extracts the main article content.

## Installation

Add to your Gemfile:

```ruby
gem "detergent"
```

## Usage

```ruby
require "detergent"

# Get a cleaned, self-contained HTML document:
clean_html = Detergent.clean(dirty_html)

# Or the title and the extracted content node (a Nokogiri node):
title, content = Detergent.extract(dirty_html)

# A Cleaner instance is reusable if you're processing many pages:
cleaner = Detergent::Cleaner.new
clean_html = cleaner.clean(dirty_html)
title = cleaner.title(dirty_html)
```

## How it works

1. A first pass prunes obvious junk (scripts, styles, iframes, nav, headers, footers, hidden elements).
2. Each remaining node is scored on how likely it is to be the main content (paragraph count, text length, link density, media, suspicious class names, etc.).
3. The highest-scoring node is located and walked up to an appropriate semantic container.
4. A second pass cleans that content of empty and suspect elements.

## License

[WTFPL](LICENSE)
