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

      @scores[node] = compute_score(node)
    end

    private

    def compute_score(node)
      stats = stats_for(node)
      score = 0
      tag = node.name.downcase

      # Positive indicators for main content
      score += ARTICLE_TAG_BONUS if tag == 'article'
      score += MAIN_TAG_BONUS if tag == 'main'
      score += MAIN_ROLE_BONUS if node['role'].to_s.downcase == 'main'

      # Paragraphs and raw text are strong indicators of article content
      score += stats[:paragraphs] * POINTS_PER_PARAGRAPH
      score += stats[:text_length] / CHARS_PER_TEXT_POINT
      score += stats[:long_paragraphs] * LONG_PARAGRAPH_BONUS

      # High link density suggests navigation
      if stats[:text_length] > 0
        link_density = stats[:links].to_f / (stats[:text_length] / 100.0)
        score -= (link_density * LINK_DENSITY_PENALTY).to_i
      end

      # Media, blockquotes, and lists all suggest article content
      score += stats[:media] * POINTS_PER_MEDIA
      score += stats[:blockquotes] * POINTS_PER_BLOCKQUOTE
      score += stats[:lists] * POINTS_PER_LIST

      # Penalty for suspicious classes/ids
      classes = node['class'].to_s.downcase
      ids = node['id'].to_s.downcase

      score -= SIDEBAR_PENALTY if classes.include?('sidebar') || ids.include?('sidebar')
      score -= COMMENT_PENALTY if classes.include?('comment') || ids.include?('comment')
      score -= AD_PENALTY if classes.include?('ad') || ids.include?('ad')
      score -= SOCIAL_PENALTY if classes.include?('social') || ids.include?('social')

      [score, 0].max # Don't return negative scores
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
