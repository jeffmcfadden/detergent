# frozen_string_literal: true

require_relative "test_helper"

class TestDetergent < Minitest::Test
  SAMPLE_HTML = <<~HTML
    <html>
      <head>
        <title>My Great Article</title>
        <script>var junk = true;</script>
      </head>
      <body>
        <nav><a href="/">Home</a> <a href="/about">About</a></nav>
        <div class="sidebar">Sidebar junk</div>
        <article>
          <h1>My Great Article</h1>
          <p>#{"This is the main content of the article. " * 10}</p>
          <p>#{"Here is another substantial paragraph of content. " * 10}</p>
        </article>
        <footer>Copyright 2026</footer>
      </body>
    </html>
  HTML

  def setup
    @cleaner = Detergent::Cleaner.new
  end

  def test_extracts_title
    assert_equal "My Great Article", @cleaner.title(SAMPLE_HTML)
  end

  def test_clean_keeps_main_content
    cleaned = @cleaner.clean(SAMPLE_HTML)

    assert_includes cleaned, "This is the main content of the article."
    assert_includes cleaned, "<title>My Great Article</title>"
  end

  def test_clean_removes_junk
    cleaned = @cleaner.clean(SAMPLE_HTML)

    refute_includes cleaned, "var junk"
    refute_includes cleaned, "Sidebar junk"
    refute_includes cleaned, "Copyright 2026"
    refute_includes cleaned, "<nav>"
  end

  def test_obvious_junk_matcher
    matcher = Detergent::Matchers::ObviousJunkMatcher.new
    doc = Nokogiri::HTML("<body><script>x</script><div hidden style='display:none'>hi</div><p>hello</p></body>")

    assert matcher.match?(doc.at("script"))
    assert matcher.match?(doc.at("div"))
    refute matcher.match?(doc.at("p"))
  end

  def test_node_scorer_prefers_article_content
    doc = Nokogiri::HTML(SAMPLE_HTML)
    scorer = Detergent::NodeScorer.new

    article_score = scorer.score(doc.at("article"))
    nav_score = scorer.score(doc.at("nav"))

    assert_operator article_score, :>, nav_score
  end

  def test_clean_produces_valid_document_shell
    cleaned = @cleaner.clean(SAMPLE_HTML)

    assert_includes cleaned, "<!DOCTYPE html>"
    assert_includes cleaned, "<body>"
    assert_includes cleaned, "</body>"
  end

  def test_clean_escapes_title
    html = SAMPLE_HTML.sub("<title>My Great Article</title>", "<title>Ben &amp; Jerry's &lt;3</title>")
    cleaned = @cleaner.clean(html)

    assert_includes cleaned, "<title>Ben &amp; Jerry&#39;s &lt;3</title>"
  end

  def test_extract_returns_title_and_content_node
    title, content = @cleaner.extract(SAMPLE_HTML)

    assert_equal "My Great Article", title
    assert_kind_of Nokogiri::XML::Node, content
    assert_includes content.text, "This is the main content of the article."
  end

  def test_module_level_convenience_methods
    assert_includes Detergent.clean(SAMPLE_HTML), "This is the main content of the article."

    title, _content = Detergent.extract(SAMPLE_HTML)
    assert_equal "My Great Article", title
  end

  def test_version
    assert_equal "2.2.0", Detergent::VERSION
  end
end
