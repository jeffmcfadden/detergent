# frozen_string_literal: true

module Detergent
  # Renders a cleaned content node as Markdown. Expects the article-shaped
  # markup that comes out of extraction; it is not a general-purpose
  # HTML-to-Markdown converter.
  #
  # The formatting decisions live in small hook methods (heading, link,
  # image, ...) so TextRenderer can subclass this and strip the syntax.
  class MarkdownRenderer
    def render(node)
      # Route through render_block so a root that is itself a block
      # element (a ul, a blockquote) gets its block treatment; generic
      # containers and fragments fall through to render_blocks.
      output = node.element? ? render_block(node) : render_blocks(node)
      output.gsub(/\n{3,}/, "\n\n").strip
    end

    private

    INLINE_TAGS = %w[a strong b em i code span img br sub sup small u s
                     strike mark abbr time].freeze

    def inline?(node)
      node.text? || (node.element? && INLINE_TAGS.include?(node.name.downcase))
    end

    # Walk a container's children, gathering runs of inline content into
    # paragraphs and rendering block elements between them.
    def render_blocks(node)
      out = []
      buffer = +""

      node.children.each do |child|
        if inline?(child)
          buffer << inline(child)
        elsif child.element?
          out << buffer.strip unless buffer.strip.empty?
          buffer = +""

          block = render_block(child)
          out << block unless block.empty?
        end
      end

      out << buffer.strip unless buffer.strip.empty?
      out.join("\n\n")
    end

    def render_block(node)
      tag = node.name.downcase

      case tag
      when /\Ah([1-6])\z/
        heading(Regexp.last_match(1).to_i, inline_content(node).strip)
      when 'p'
        inline_content(node).strip
      when 'blockquote'
        blockquote(render_blocks(node))
      when 'ul'
        list(node, ordered: false)
      when 'ol'
        list(node, ordered: true)
      when 'pre'
        preformatted(node.text.rstrip)
      when 'hr'
        rule
      when 'figcaption'
        caption(inline_content(node).strip)
      when 'table'
        table(node)
      else
        # Generic container (div, section, article, figure, ...)
        render_blocks(node)
      end
    end

    def inline(node)
      return node.text.gsub(/\s+/, " ") if node.text?

      case node.name.downcase
      when 'br' then "\n"
      when 'img' then image(node)
      when 'a' then link(node)
      when 'strong', 'b' then wrap(node, "**")
      when 'em', 'i' then wrap(node, "*")
      when 'code' then code_span(node)
      else inline_content(node)
      end
    end

    def inline_content(node)
      node.children.map { |child| inline(child) }.join
    end

    def list(node, ordered:)
      items = node.children.select { |c| c.element? && c.name.downcase == 'li' }

      items.each_with_index.map do |li, index|
        marker = ordered ? "#{index + 1}. " : "- "
        indent = " " * marker.length
        marker + render_blocks(li).gsub("\n", "\n#{indent}")
      end.join("\n")
    end

    def table(node)
      rows = node.xpath('.//tr')
      return "" if rows.empty?

      lines = rows.map do |row|
        cells = row.xpath('./th | ./td').map { |cell| inline_content(cell).strip }
        "| #{cells.join(' | ')} |"
      end

      column_count = rows.first.xpath('./th | ./td').length
      lines.insert(1, "|#{' --- |' * column_count}")
      lines.join("\n")
    end

    # -- Formatting hooks, overridden by TextRenderer --

    def heading(level, text)
      "#{'#' * level} #{text}"
    end

    def blockquote(content)
      content.split("\n").map { |line| line.empty? ? ">" : "> #{line}" }.join("\n")
    end

    def preformatted(text)
      "```\n#{text}\n```"
    end

    def rule
      "---"
    end

    def caption(text)
      text.empty? ? "" : "*#{text}*"
    end

    def link(node)
      text = inline_content(node).strip
      href = node['href'].to_s
      return text if href.empty? || text.empty?

      "[#{text}](#{href})"
    end

    def image(node)
      src = node['src'].to_s
      return "" if src.empty?

      alt = node['alt'].to_s.gsub(/\s+/, " ").strip
      "![#{alt}](#{src})"
    end

    def wrap(node, marker)
      content = inline_content(node).strip
      content.empty? ? "" : "#{marker}#{content}#{marker}"
    end

    def code_span(node)
      content = node.text.strip
      content.empty? ? "" : "`#{content}`"
    end
  end
end
