# frozen_string_literal: true

module Detergent
  # Fallback extractor for index pages: link aggregators, front pages, and
  # directories (e.g. the Hacker News front page) where the "content" is a
  # list of links to other pages. The article locator correctly rejects
  # these — link density is its strongest navigation signal — so when it
  # finds nothing, this extractor looks for a substantial collection of
  # title-like links and returns them as a synthetic list node that flows
  # through the normal cleaning and rendering pipeline.
  class LinkListExtractor
    # Links with less text than this are treated as chrome ("login",
    # "hide", "42 comments"), not titles.
    MIN_LINK_TEXT_LENGTH = 15

    # Fewer title-like links than this isn't an index page.
    MIN_LINKS = 10

    # Returns a synthetic <ul> of the page's title-like links, or nil if
    # the page doesn't look like a link index.
    def extract(body)
      links = title_like_links(body)
      return nil if links.length < MIN_LINKS

      build_list(body.document, links)
    end

    private

    def title_like_links(body)
      seen_hrefs = {}

      body.css("a").filter_map do |link|
        href = link["href"].to_s
        next if href.empty? || href.start_with?("#", "javascript:")

        text = link.text.gsub(/\s+/, " ").strip
        next if text.length < MIN_LINK_TEXT_LENGTH
        next if seen_hrefs[href]

        seen_hrefs[href] = true
        [text, href]
      end
    end

    def build_list(doc, links)
      list = Nokogiri::XML::Node.new("ul", doc)

      links.each do |text, href|
        item = Nokogiri::XML::Node.new("li", doc)
        anchor = Nokogiri::XML::Node.new("a", doc)
        anchor["href"] = href
        anchor.content = text
        item.add_child(anchor)
        list.add_child(item)
      end

      list
    end
  end
end
