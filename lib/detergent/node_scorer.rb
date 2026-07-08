# frozen_string_literal: true

module Detergent
  # Scores nodes on how likely they are to be the page's main content.
  #
  # Descendant statistics are computed bottom-up, with each node's stats
  # built from its children's already-computed stats, so scoring every
  # node in a document is O(n) instead of a full-subtree scan per node.
  # A scorer instance is scoped to a single parse of a single document;
  # discard it once the tree is mutated.
  class NodeScorer
    ARTICLE_TAG_BONUS = 100
    MAIN_TAG_BONUS = 50
    MAIN_ROLE_BONUS = 25
    POINTS_PER_PARAGRAPH = 5
    CHARS_PER_TEXT_POINT = 100
    LINK_DENSITY_PENALTY = 10
    POINTS_PER_MEDIA = 10
    LONG_PARAGRAPH_BONUS = 15
    LONG_PARAGRAPH_LENGTH = 100
    POINTS_PER_BLOCKQUOTE = 10
    POINTS_PER_LIST = 5
    SIDEBAR_PENALTY = 50
    COMMENT_PENALTY = 50
    AD_PENALTY = 70
    SOCIAL_PENALTY = 70

    def initialize
      @scores = {}.compare_by_identity
      @stats = {}.compare_by_identity
    end

    def score(node)
      cached = @scores[node]
      return cached unless cached.nil?
      return 0 unless node.element?

      total = components_for(node).sum { |_label, points| points }
      @scores[node] = [total, 0].max # Don't return negative scores
    end

    # Returns the score as [label, points] pairs explaining where every
    # point came from. Debugging aid used by Inspector.
    def explain(node)
      return [] unless node.element?

      components_for(node)
    end

    private

    def components_for(node)
      stats = stats_for(node)
      tag = node.name.downcase
      parts = []

      # Positive indicators for main content
      parts << ["<article> tag", ARTICLE_TAG_BONUS] if tag == 'article'
      parts << ["<main> tag", MAIN_TAG_BONUS] if tag == 'main'
      parts << ["role=main", MAIN_ROLE_BONUS] if node['role'].to_s.downcase == 'main'

      # Paragraphs and raw text are strong indicators of article content
      if stats[:paragraphs] > 0
        parts << ["#{stats[:paragraphs]} paragraphs", stats[:paragraphs] * POINTS_PER_PARAGRAPH]
      end
      if (text_points = stats[:text_length] / CHARS_PER_TEXT_POINT) > 0
        parts << ["#{stats[:text_length]} chars of text", text_points]
      end
      if stats[:long_paragraphs] > 0
        parts << ["#{stats[:long_paragraphs]} long paragraphs", stats[:long_paragraphs] * LONG_PARAGRAPH_BONUS]
      end

      # High link density suggests navigation
      if stats[:text_length] > 0 && stats[:links] > 0
        link_density = stats[:links].to_f / (stats[:text_length] / 100.0)
        parts << ["link density #{link_density.round(2)} (#{stats[:links]} links)",
                  -(link_density * LINK_DENSITY_PENALTY).to_i]
      end

      # Media, blockquotes, and lists all suggest article content
      parts << ["#{stats[:media]} media elements", stats[:media] * POINTS_PER_MEDIA] if stats[:media] > 0
      parts << ["#{stats[:blockquotes]} blockquotes", stats[:blockquotes] * POINTS_PER_BLOCKQUOTE] if stats[:blockquotes] > 0
      parts << ["#{stats[:lists]} lists", stats[:lists] * POINTS_PER_LIST] if stats[:lists] > 0

      # Penalty for suspicious classes/ids
      classes = node['class'].to_s.downcase
      ids = node['id'].to_s.downcase

      parts << ["suspect 'sidebar' class/id", -SIDEBAR_PENALTY] if classes.include?('sidebar') || ids.include?('sidebar')
      parts << ["suspect 'comment' class/id", -COMMENT_PENALTY] if classes.include?('comment') || ids.include?('comment')
      parts << ["suspect 'ad' class/id", -AD_PENALTY] if classes.include?('ad') || ids.include?('ad')
      parts << ["suspect 'social' class/id", -SOCIAL_PENALTY] if classes.include?('social') || ids.include?('social')

      parts
    end

    # Statistics about a node's descendants (not the node itself),
    # aggregated from its children's stats in a single pass.
    def stats_for(node)
      cached = @stats[node]
      return cached if cached

      stats = { text_length: 0, links: 0, paragraphs: 0, long_paragraphs: 0,
                media: 0, blockquotes: 0, lists: 0 }

      node.children.each do |child|
        if child.text?
          stats[:text_length] += child.text.strip.length
        elsif child.element?
          child_stats = stats_for(child)
          stats.each_key { |key| stats[key] += child_stats[key] }

          case child.name.downcase
          when 'a'
            stats[:links] += 1
          when 'p'
            stats[:paragraphs] += 1
            stats[:long_paragraphs] += 1 if child_stats[:text_length] > LONG_PARAGRAPH_LENGTH
          when 'img', 'picture', 'figure'
            stats[:media] += 1
          when 'blockquote'
            stats[:blockquotes] += 1
          when 'ul', 'ol'
            stats[:lists] += 1
          end
        end
      end

      @stats[node] = stats
    end
  end
end
