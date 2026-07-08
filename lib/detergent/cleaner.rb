# frozen_string_literal: true

module Detergent
  # Orchestrates cleaning: prunes obvious junk, locates the main content,
  # scrubs it, and renders the result back out as a standalone document.
  class Cleaner
    def initialize
      @obvious_junk_matcher = Matchers::ObviousJunkMatcher.new
      @removable_node_matcher = Matchers::RemovableNodeMatcher.new
    end

    # Returns a complete, standalone HTML document containing only the
    # page's title and its extracted main content.
    def clean(html)
      title, content = extract(html)

      # The content root is usually an inner element (article, main, div),
      # so wrap it in a body tag unless it already is one.
      body = if content.nil? || content.name.downcase == "body"
        content.to_s
      else
        "<body>#{content}</body>"
      end

      <<~HTML
        <!DOCTYPE html>
        <html>
          <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>#{CGI.escapeHTML(title.to_s)}</title>
          </head>
          #{body}
        </html>
      HTML
    end

    # Returns [title, content]: the page title and the cleaned Nokogiri
    # node containing the main content (nil if none was found).
    def extract(html)
      doc = Nokogiri::HTML5(html)
      title = extract_title(doc)

      body = doc.at('body')
      content = nil

      if body
        # First remove the most egregious crap, like obvious ads, etc.
        prune(node: body, matcher: @obvious_junk_matcher)

        # Score caches are only valid for a single parse of a single
        # document, so the scorer and locator are built per extract.
        content = ContentLocator.new(NodeScorer.new).locate(body)

        # Apply second-pass cleaning to the content
        if content
          clean_node(content)
          strip_junk_attributes(content)
        end
      end

      [title, content]
    end

    def title(html)
      extract_title(Nokogiri::HTML5(html))
    end

    private

    def extract_title(doc)
      title_node = doc.at('title')
      title_node ? title_node.text.strip : ""
    end

    def prune(node:, matcher:)
      node.children.to_a.each do |child|
        next unless child.element?

        # Match first so we never bother walking a subtree we're removing
        if matcher.match?(child)
          child.remove
        else
          prune(node: child, matcher: matcher)
        end
      end

      node
    end

    # Recursively process an element's children and remove any that are "empty"
    def clean_node(node, within_article: false)
      within_article ||= node.name.downcase == "article"

      # Iterate over a copy of the children to avoid modification issues
      node.children.to_a.each do |child|
        if child.element?
          clean_node(child, within_article: within_article)  # process children first
          # Remove the child if it qualifies as "empty"

          if child.name.downcase == "aside" && !within_article
            child.remove
          elsif removable?(child)
            child.remove
          else
            strip_junk_attributes(child)
          end
        end
      end
    end

    # Strip presentation and tracking attributes from a kept element.
    # Must run only after removability has been decided, because the
    # matchers read class and style. Keeps id so in-page anchors work.
    def strip_junk_attributes(node)
      node.attribute_nodes.each do |attr|
        name = attr.name.downcase
        if %w[class style].include?(name) || name.start_with?("on", "data-")
          node.remove_attribute(attr.name)
        end
      end
    end

    # An element is removable if:
    # - It is a <script> or <style> tag (non-visible content), or other element we don't want
    # - It has no descendant text nodes (ignoring whitespace)
    def removable?(node)
      @removable_node_matcher.match?(node)
    end
  end
end
