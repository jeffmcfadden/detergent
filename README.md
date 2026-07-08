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

# Or the extracted main content as Markdown or plain text:
markdown = Detergent.markdown(dirty_html)
text = Detergent.text(dirty_html)

# A Cleaner instance is reusable if you're processing many pages:
cleaner = Detergent::Cleaner.new
clean_html = cleaner.clean(dirty_html)
title = cleaner.title(dirty_html)
```

## Command line

```
detergent article.html                    # extracted content as Markdown
detergent --format text https://example.com/post
detergent --format html article.html     # cleaned standalone document
detergent --format title article.html
```

## Debugging

When extraction picks the wrong node (or nothing at all), the Inspector
reports every decision: what each pass removed, the top-scoring nodes with
point-by-point score breakdowns, and whether the best candidate cleared the
minimum content score.

```
$ detergent --format debug page.html

Detergent 2.3.0 debug report
Title: "Hacker News"
Verdict: NO MAIN CONTENT (best score 10 < threshold 25)

First pass (obvious junk): removed 1 nodes (script x1)

Top scoring nodes after first pass:
     10  td
           +10  1 media elements
      0  tr#48825749.athing.submission          20.Tenda firmware (multiple versions) co...
           -34  link density 3.45 (3 links)
...
```

Or from Ruby: `puts Detergent::Inspector.new.analyze(html)` — the returned
report object also exposes `located?`, `best_score`, `top_nodes`, and
`removals` for programmatic use.

## How it works

1. A first pass prunes obvious junk (scripts, styles, iframes, nav, headers, footers, hidden elements).
2. Each remaining node is scored on how likely it is to be the main content (paragraph count, text length, link density, media, suspicious class names, etc.).
3. The highest-scoring node is located and walked up to an appropriate semantic container.
4. A second pass cleans that content of empty and suspect elements.

Pages with no article content but a substantial set of title-like links —
index pages and link aggregators like the Hacker News front page — fall
back to link-list extraction: the result is a clean list of the page's
links instead of an article.

## License

[WTFPL](LICENSE)
