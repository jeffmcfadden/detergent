module Detergent
  module Matchers
    class ObviousJunkMatcher
      def match?(node)
        tag = node.name.downcase

        # Always remove these tags
        return true if %w(script style link iframe noscript).include?(tag)

        # Remove hidden elements
        return true if node['aria-hidden'] == 'true'

        # Remove display:none elements
        style = node['style'].to_s.downcase
        return true if style.include?('display:none') || style.include?('display: none')

        # Remove structural navigation
        return true if %w(nav header footer).include?(tag)
        return true if node['role'].to_s.downcase == 'navigation'

        false
      end
    end
  end
end
