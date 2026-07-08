# frozen_string_literal: true

module Detergent
  module Matchers
    # Second-pass matcher: applied within the extracted content to drop
    # leftover chrome, suspect containers, and empty elements.
    class RemovableNodeMatcher
      REMOVABLE_TAGS = (JUNK_TAGS + %w[footer nav] + FORM_TAGS).freeze

      SUSPECT_CLASSES = %w[comments-show comments actionbar related-stories navigation
                           nodisplay sidebar admz hidden header footer social share].freeze

      SUSPECT_IDS = %w[header navigation ad admz sidebar related-stories hidden].freeze

      def match?(node)
        tag = node.name.downcase

        # Remove button elements with Share or Save aria-labels
        if tag == "button"
          aria_label = node['aria-label'].to_s.downcase
          return true if ["share", "save"].include?(aria_label)
        end

        # Elements we don't care about
        return true if REMOVABLE_TAGS.include?(tag)

        # Get rid of elements with classnames or ids that look suspect
        class_list = node['class'].to_s.downcase.split(" ")
        return true if class_list.any? { SUSPECT_CLASSES.include?(_1) }

        id_list = node['id'].to_s.downcase.split(" ")
        return true if id_list.any? { SUSPECT_IDS.include?(_1) }

        # Get rid of hidden elements
        return true if Detergent.display_none?(node)

        # Don't remove images, etc in this step, which never have text content:
        return false if MEDIA_TAGS.include?(tag)

        # Don't remove if any descendants are imgs, etc:
        return false if node.xpath(".//img | .//picture | .//figure").any?

        # Using XPath to find any descendant text node that contains non-whitespace characters.
        node.xpath(".//text()[normalize-space()]").empty?
      end
    end
  end
end
