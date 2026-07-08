# frozen_string_literal: true

module Detergent
  module Matchers
    # First-pass matcher: junk that can be removed on sight, before any
    # content scoring happens.
    class ObviousJunkMatcher
      def match?(node)
        tag = node.name.downcase

        # Always remove these tags
        return true if JUNK_TAGS.include?(tag)

        # Remove hidden elements
        return true if node['aria-hidden'] == 'true'
        return true if Detergent.display_none?(node)

        # Remove structural navigation
        return true if CHROME_TAGS.include?(tag)
        return true if node['role'].to_s.downcase == 'navigation'

        false
      end
    end
  end
end
