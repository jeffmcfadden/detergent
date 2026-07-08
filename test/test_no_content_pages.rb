# frozen_string_literal: true

require_relative "test_helper"

# Pages with no main content (index pages, link aggregators) must report
# "nothing found" rather than electing a degenerate winner like a logo
# cell. Regression coverage for the Hacker News front page, where every
# node's link density cancels its text score.
class TestNoContentPages < Minitest::Test
  HN_FRONT_PAGE = File.read(File.expand_path("fixtures/hn_front_page.html", __dir__))

  LINK_LIST_PAGE = <<~HTML
    <html>
      <head><title>Links Directory</title></head>
      <body>
        <img src="/logo.png" alt="logo">
        <ul>
          #{30.times.map { |i| "<li><a href='/story#{i}'>Interesting story number #{i}</a> <a href='/comments#{i}'>comments</a></li>" }.join("\n")}
        </ul>
      </body>
    </html>
  HTML

  def test_hn_front_page_reports_no_content
    title, content = Detergent.extract(HN_FRONT_PAGE)

    assert_equal "Hacker News", title
    assert_nil content
  end

  def test_hn_front_page_text_and_markdown_are_empty
    assert_equal "", Detergent.text(HN_FRONT_PAGE)
    assert_equal "", Detergent.markdown(HN_FRONT_PAGE)
  end

  def test_hn_front_page_clean_still_returns_a_valid_shell
    cleaned = Detergent.clean(HN_FRONT_PAGE)

    assert_includes cleaned, "<title>Hacker News</title>"
    refute_includes cleaned, "y18.svg"
  end

  def test_synthetic_link_list_reports_no_content
    _title, content = Detergent.extract(LINK_LIST_PAGE)

    assert_nil content
  end

  def test_real_articles_clear_the_minimum_score
    fixture = File.read(File.expand_path("fixtures/coffee_article.html", __dir__))
    _title, content = Detergent.extract(fixture)

    refute_nil content
  end
end
