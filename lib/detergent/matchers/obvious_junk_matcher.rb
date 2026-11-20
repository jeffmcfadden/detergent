# frozen_string_literal: true

module Detergent
  module Matchers
    # First-pass matcher: junk that can be removed on sight, before any
    # content scoring happens.
    class ObviousJunkMatcher
      STRUCTURAL_TAGS = %w[div section ul ol li aside].freeze
      CHROME_NAME = /(?:\A|[-_\s])(?:menu|navigation|sidebar|related|recommendations|newsletter|subscribe|social|share|sharing|comments?|disqus|advertisement|advertising|advert|ad|ads|promo|cookie)(?:\z|[-_\s])/i

      def match?(node)
        tag = node.name.downcase

        # Always remove these tags
        return true if JUNK_TAGS.include?(tag)

        # Remove hidden elements
        return true if node.key?('hidden')
        return true if node['aria-hidden'] == 'true'
        return true if Detergent.display_none?(node)

        # Remove structural navigation
        return true if CHROME_TAGS.include?(tag)
        return true if %w[navigation banner contentinfo].include?(node['role'].to_s.downcase)

        # Match whole class/id components, not substrings such as "ad" in
        # "reading". Remove these before scoring so widgets cannot inflate a page.
        if STRUCTURAL_TAGS.include?(tag)
          return true if CHROME_NAME.match?([node['class'], node['id']].compact.join(' '))
        end

        false
      end
    end
  end
end
