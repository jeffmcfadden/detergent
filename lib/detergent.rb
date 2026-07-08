# frozen_string_literal: true

require "cgi/escape"
require "nokogiri"

module Detergent
  # Tags that never contain readable content.
  JUNK_TAGS = %w[script style link iframe noscript].freeze

  # Structural chrome that surrounds the content.
  CHROME_TAGS = %w[nav header footer].freeze

  # Interactive elements that don't belong in cleaned output.
  FORM_TAGS = %w[form select textarea].freeze

  # Media elements that legitimately contain no text.
  MEDIA_TAGS = %w[img picture figure].freeze

  def self.display_none?(node)
    style = node["style"].to_s.downcase
    style.include?("display:none") || style.include?("display: none")
  end

  # Returns a cleaned, standalone HTML document.
  def self.clean(html)
    Cleaner.new.clean(html)
  end

  # Returns [title, content]: the page title and the cleaned Nokogiri
  # node containing the main content (nil if none was found).
  def self.extract(html)
    Cleaner.new.extract(html)
  end

  # Returns the extracted main content as Markdown.
  def self.markdown(html)
    Cleaner.new.markdown(html)
  end

  # Returns the extracted main content as plain text.
  def self.text(html)
    Cleaner.new.text(html)
  end
end

require_relative "detergent/version"
require_relative "detergent/node_scorer"
require_relative "detergent/content_locator"
require_relative "detergent/link_list_extractor"
require_relative "detergent/markdown_renderer"
require_relative "detergent/text_renderer"
require_relative "detergent/matchers/obvious_junk_matcher"
require_relative "detergent/matchers/removable_node_matcher"
require_relative "detergent/cleaner"
require_relative "detergent/inspector"
