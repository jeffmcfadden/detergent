module Detergent
  module Matchers
    class RemovableNodeMatcher

      def match?(node)
        # Remove button elements with Share or Save aria-labels
        if node.name.downcase == "button"
          aria_label = node['aria-label'].to_s.downcase
          return true if ["share", "save"].include?(aria_label)
        end

        # Remove nav with role=navigation
        if node.name.downcase == "nav"
          return true if node['role'].to_s.downcase == "navigation"
        end

        # Elements we don't care about
        return true if %w(link iframe script style footer nav form select textarea).include?(node.name.downcase)

        # Get rid of elements with classnames that look suspect
        class_list = node['class'].to_s.downcase.split(" ")
        return true if class_list.any?{ %w(comments-show comments actionbar related-stories navigation nodisplay sidebar admz hidden header footer social share).include?(_1) }

        id_list = node['id'].to_s.downcase.split(" ")
        return true if id_list.any?{ %w(header navigation ad admz sidebar related-stories hidden).include?(_1) }

        # Get rid of elements with inline styles that look suspect
        style_list = node['style'].to_s.downcase.split(";")
        return true if style_list.any?{ ["display: none", "display:none"].include?(_1) }

        # Don't remove images, etc in this step, which never have text content:
        return false if %w(img picture figure).include?(node.name.downcase)

        # Don't remove if any descendants are imgs, etc:
        return false if node.xpath(".//img | .//picture | .//figure").any?

        # Using XPath to find any descendant text node that contains non-whitespace characters.
        node.xpath(".//text()[normalize-space()]").empty?
      end
    end
  end
end
