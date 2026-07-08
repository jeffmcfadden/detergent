# frozen_string_literal: true

module Detergent
  # Renders a cleaned content node as plain text: the same document
  # structure as MarkdownRenderer (blank-line paragraphs, list bullets)
  # with all Markdown syntax stripped. Images are dropped entirely.
  class TextRenderer < MarkdownRenderer
    private

    def heading(_level, text)
      text
    end

    def blockquote(content)
      content
    end

    def preformatted(text)
      text
    end

    def rule
      ""
    end

    def caption(text)
      text
    end

    def link(node)
      inline_content(node).strip
    end

    def image(_node)
      ""
    end

    def wrap(node, _marker)
      inline_content(node).strip
    end

    def code_span(node)
      node.text.strip
    end
  end
end
