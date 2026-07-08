# frozen_string_literal: true

module Detergent
  # Instruments a full extraction run and reports every decision made
  # along the way: what the first pass removed, how the tree scored (with
  # per-node score breakdowns), whether the best candidate cleared the
  # minimum-score threshold, which content root was chosen, and what the
  # second pass removed.
  #
  #   puts Detergent::Inspector.new.analyze(html)
  #
  # Also available from the command line:
  #
  #   detergent --format debug page.html
  class Inspector
    TOP_NODE_COUNT = 10
    BREAKDOWN_COUNT = 3

    ScoredNode = Struct.new(:score, :descriptor, :preview, :breakdown)

    class Report
      attr_accessor :title, :best_score, :content_root, :content_root_size, :top_nodes, :strategy
      attr_reader :removals

      def initialize
        @removals = { first_pass: [], second_pass: [] }
        @top_nodes = []
        @best_score = 0
      end

      def located?
        !content_root.nil?
      end

      def to_s
        lines = ["Detergent #{Detergent::VERSION} debug report"]
        lines << "Title: #{title.inspect}"
        lines << verdict
        lines << ""
        lines << removal_summary(:first_pass, "First pass (obvious junk)")
        lines << ""
        lines << "Top scoring nodes after first pass:"

        top_nodes.each do |node|
          lines << format("  %5d  %-38s %s", node.score, node.descriptor, node.preview)
          node.breakdown&.each do |label, points|
            lines << format("         %+5d  %s", points, label)
          end
        end

        lines << ""
        lines << if located?
          "Content root: #{content_root} (#{content_root_size} chars of HTML)"
        else
          "Content root: (none)"
        end
        lines << removal_summary(:second_pass, "Second pass (within content)")
        lines.join("\n")
      end

      private

      def verdict
        threshold = ContentLocator::MINIMUM_CONTENT_SCORE

        case strategy
        when :article
          "Verdict: article content located (best score #{best_score}, threshold #{threshold})"
        when :link_list
          "Verdict: no article content (best score #{best_score} < threshold #{threshold}); extracted link list instead"
        else
          "Verdict: NO MAIN CONTENT (best score #{best_score} < threshold #{threshold})"
        end
      end

      def removal_summary(pass, label)
        removed = removals[pass]
        return "#{label}: removed 0 nodes" if removed.empty?

        tally = removed.tally.sort_by { |_tag, count| -count }
                       .map { |tag, count| "#{tag} x#{count}" }.join(", ")
        "#{label}: removed #{removed.length} nodes (#{tally})"
      end
    end

    def analyze(html)
      @report = Report.new

      title, content = Cleaner.new(observer: self).extract(html)
      @report.title = title

      if content
        @report.content_root = descriptor(content)
        @report.content_root_size = content.to_s.length
      end

      @report
    end

    # -- Cleaner observer callbacks --

    def node_removed(node, pass:)
      @report.removals[pass] << node.name.downcase
    end

    # Called after the first pass, before content location, with the same
    # scorer the locator will use — so the report matches its decisions.
    def content_pruned(body, scorer)
      scored = ([body] + body.xpath(".//*").to_a)
               .map { |node| [scorer.score(node), node] }
               .sort_by { |score, _node| -score }
               .first(TOP_NODE_COUNT)

      # Materialize descriptors/previews now; the tree mutates after this.
      @report.top_nodes = scored.each_with_index.map do |(score, node), index|
        breakdown = index < BREAKDOWN_COUNT ? scorer.explain(node) : nil
        ScoredNode.new(score, descriptor(node), preview(node), breakdown)
      end

      @report.best_score = scored.first&.first || 0
    end

    def extraction_strategy(strategy)
      @report.strategy = strategy
    end

    private

    def descriptor(node)
      desc = +node.name.downcase

      id = node['id'].to_s
      desc << "##{id}" unless id.empty?

      classes = node['class'].to_s.split(" ")
      desc << ".#{classes.first(3).join('.')}" unless classes.empty?

      desc
    end

    def preview(node)
      text = node.text.gsub(/\s+/, " ").strip
      text.length > 60 ? "#{text[0, 60]}..." : text
    end
  end
end
