module Detergent
  class Cleaner

    def initialize
      @obvious_junk_matcher = Matchers::ObviousJunkMatcher.new
      @removable_node_matcher = Matchers::RemovableNodeMatcher.new
    end

    def clean(html)
      title, content = cleaned_html(html)

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

    def title(html)
      doc = Nokogiri::HTML(html)

      title_node = doc.at('title')
      title = title_node ? title_node.text.strip : ""

      title
    end


    def cleaned_html(html)
      doc = Nokogiri::HTML(html)

      title_node = doc.at('title')
      title = title_node ? title_node.text.strip : ""

      body = doc.at('body')
      content = nil

      # Score caches are only valid for a single parse of a single document
      @node_scorer = NodeScorer.new

      if body
        # First remove the most egregious crap, like obvious ads, etc.
        prune(node: body, matcher: Matchers::ObviousJunkMatcher.new)

        # Find the highest-scoring node in the cleaned tree
        highest_scoring = find_highest_scoring_node(body)
        return nil unless highest_scoring

        # Find the appropriate root container for that node
        content_root = find_content_root(highest_scoring)

        # Apply second-pass cleaning to the content
        if content_root
          clean_node(content_root)
        end

        content = content_root
      end

      [title, content]
    end

    private

    def prune(node:, matcher:)
      node.children.to_a.each do |child|
        if child.element?
          # Recurse first
          prune(node: child, matcher: matcher)

          child.remove if matcher.match?(child)
        end
      end

      node
    end

    # Scores a node based on how likely it is to be main content
    # Higher scores indicate more likely to be the primary article content
    def score_node(node)
      @node_scorer.score(node)
    end

    # Finds the node with the highest content score
    # Returns the node with the highest score in the tree
    def find_highest_scoring_node(node)
      return nil unless node.element?

      best_node = node
      best_score = score_node(node)

      # Recursively check all child elements
      node.children.each do |child|
        next unless child.element?

        candidate = find_highest_scoring_node(child)
        if candidate
          candidate_score = score_node(candidate)
          if candidate_score > best_score
            best_node = candidate
            best_score = candidate_score
          end
        end
      end

      best_node
    end

    # Finds an appropriate root ancestor for the given node
    # Traverses up the tree to find a good container for the main content
    # Stops at body or when we find a semantic container
    def find_content_root(node)
      return node if node.nil? || node.name.downcase == 'body'

      current = node
      best_ancestor = node

      # Traverse up the tree
      while current.parent && current.parent.element?
        parent = current.parent
        parent_tag = parent.name.downcase

        # Stop at body
        break if parent_tag == 'body'

        # Prefer semantic containers
        if %w(article main section).include?(parent_tag)
          best_ancestor = parent
        end

        # If parent has significantly more content than current node,
        # it might be a better root (captures related content)
        parent_score = score_node(parent)
        current_score = score_node(current)

        # Only move up if parent score is meaningfully higher
        # (not just marginally better due to including the child)
        if parent_score > current_score * 1.3
          best_ancestor = parent
        end

        current = parent
      end

      best_ancestor
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
            child.remove_attribute("class") # Cleanup
          end
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
