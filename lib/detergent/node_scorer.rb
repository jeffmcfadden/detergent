# frozen_string_literal: true

module Detergent
  class NodeScorer
    def initialize
      # Scores are cached per node so tree walks don't re-score subtrees.
      # A scorer instance is scoped to a single parse of a document; discard
      # it once the tree is mutated.
      @scores = {}.compare_by_identity
    end

    def score(node)
      cached = @scores[node]
      return cached unless cached.nil?

      return 0 unless node.element?

      score = 0
      tag = node.name.downcase

      # Positive indicators for main content
      score += 100 if tag == 'article'
      score += 50 if tag == 'main'
      score += 25 if node['role'].to_s.downcase == 'main'

      # Count paragraphs - strong indicator of article content
      paragraph_count = node.xpath('.//p').count
      score += paragraph_count * 5

      # Calculate text length
      begin
        text_content = node.xpath('.//text()').map(&:text).join
        text_length = text_content.strip.length
        score += (text_length / 100).to_i  # 1 point per 100 characters
      rescue StandardError
        text_length = 0
      end

      # Calculate link density (high link density suggests navigation)
      link_count = node.xpath('.//a').count
      if text_length > 0
        link_density = (link_count.to_f / (text_length / 100.0))
        score -= (link_density * 10).to_i  # Penalize high link density
      end

      # Bonus for images/figures (suggests article content)
      media_count = node.xpath('.//img | .//picture | .//figure').count
      score += media_count * 10

      # Bonus for long paragraphs
      begin
        long_paragraphs = node.xpath('.//p').select { |p| p.text.strip.length > 100 }.count
        score += long_paragraphs * 15
      rescue StandardError
        # Do nothing
      end

      # Bonus for blockquotes and lists (often in articles)
      score += node.xpath('.//blockquote').count * 10
      score += node.xpath('.//ul | .//ol').count * 5

      # Penalty for suspicious classes/ids
      classes = node['class'].to_s.downcase
      ids = node['id'].to_s.downcase

      score -= 50 if classes.include?('sidebar') || ids.include?('sidebar')
      score -= 50 if classes.include?('comment') || ids.include?('comment')
      score -= 70 if classes.include?('ad') || ids.include?('ad')
      score -= 70 if classes.include?('social') || ids.include?('social')

      @scores[node] = [score, 0].max  # Don't return negative scores
    end
  end
end
