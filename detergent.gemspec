require_relative "lib/detergent/version"

Gem::Specification.new do |spec|
  spec.name = "detergent"
  spec.version = Detergent::VERSION
  spec.authors = ["Jeff McFadden"]
  spec.email = ["55709+jeffmcfadden@users.noreply.github.com"]

  spec.summary = "Cleans up website HTML, extracting the main content."
  spec.description = "Detergent scrubs junk out of web pages: it removes ads, navigation, scripts, and other cruft, then extracts the main article content from an HTML document."
  spec.homepage = "https://github.com/jeffmcfadden/detergent"
  spec.license = "WTFPL"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*.rb", "exe/*", "LICENSE", "README.md"]
  spec.bindir = "exe"
  spec.executables = ["detergent"]
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.15"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
end
