# frozen_string_literal: true

module Detergent
  # Locates the main content node within a document's body: finds the
  # highest-scoring node in the tree, then walks up its ancestors to find
  # the best root container for the content.
  class ContentLocator
    SEMANTIC_CONTAINERS = %w[article main section].freeze

    # A parent must beat the best root found so far by this ratio to be
    # promoted — not just score marginally higher from including the child.
    PARENT_PROMOTION_RATIO = 1.3

    def initialize(scorer)
      @scorer = scorer
    end

    def locate(body)
      highest_scoring = find_highest_scoring_node(body)
      return nil unless highest_scoring

      find_content_root(highest_scoring)
    end

    private

    def score(node)
      @scorer.score(node)
    end

    # Finds the node with the highest content score in the tree
    def find_highest_scoring_node(node)
      return nil unless node.element?

      best_node = node
      best_score = score(node)

      node.children.each do |child|
        next unless child.element?

        candidate = find_highest_scoring_node(child)
        if candidate
          candidate_score = score(candidate)
          if candidate_score > best_score
            best_node = candidate
            best_score = candidate_score
          end
        end
      end

      best_node
    end

    # Walks up from the given node to find a good container for the main
    # content, preferring semantic containers and ancestors that score
    # meaningfully higher than the best root found so far. Stops at body.
    def find_content_root(node)
      return node if node.name.downcase == 'body'

      best_ancestor = node
      best_score = score(node)
      current = node

      while current.parent&.element?
        parent = current.parent
        parent_tag = parent.name.downcase

        break if parent_tag == 'body'

        if SEMANTIC_CONTAINERS.include?(parent_tag) ||
           score(parent) > best_score * PARENT_PROMOTION_RATIO
          best_ancestor = parent
          best_score = score(parent)
        end

        current = parent
      end

      best_ancestor
    end
  end
end
