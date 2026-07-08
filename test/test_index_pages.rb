# frozen_string_literal: true

require_relative "test_helper"

# Index pages (link aggregators, front pages) have no article content —
# the link-density penalty correctly zeroes out their scores — so
# extraction falls back to the link-list strategy. Regression coverage
# for the Hacker News front page. Pages with neither article content nor
# a substantial link list still report nothing found.
class TestIndexPages < Minitest::Test
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

  EMPTY_PAGE = <<~HTML
    <html>
      <head><title>Nothing Here</title></head>
      <body>
        <a href="/">Home</a>
        <p>Hi.</p>
      </body>
    </html>
  HTML

  def test_hn_front_page_falls_back_to_link_list
    title, content = Detergent.extract(HN_FRONT_PAGE)

    assert_equal "Hacker News", title
    assert_equal "ul", content.name
    assert_operator content.css("li").length, :>=, 20
  end

  def test_hn_front_page_markdown_is_a_list_of_story_links
    markdown = Detergent.markdown(HN_FRONT_PAGE)

    assert_includes markdown, "- ["
    # A story title from the snapshot, with its href
    assert_match(/- \[Tenda firmware .*\]\(.+\)/, markdown)
    # Chrome links are too short to qualify as titles
    refute_includes markdown, "](newest)"
    refute_includes markdown, "y18.svg"
  end

  def test_hn_front_page_text_lists_story_titles
    text = Detergent.text(HN_FRONT_PAGE)

    assert_includes text, "- Tenda firmware"
    refute_includes text, "]("
  end

  def test_link_titles_are_deduplicated_by_href
    _title, content = Detergent.extract(HN_FRONT_PAGE)
    hrefs = content.css("a").map { |a| a["href"] }

    assert_equal hrefs.uniq, hrefs
  end

  def test_synthetic_link_list_page_extracts_all_stories
    _title, content = Detergent.extract(LINK_LIST_PAGE)

    assert_equal "ul", content.name
    assert_equal 30, content.css("li").length
    # The short "comments" links don't qualify as titles
    refute_includes content.to_s, "comments"
  end

  def test_page_with_no_content_and_no_link_list_reports_nothing
    _title, content = Detergent.extract(EMPTY_PAGE)

    assert_nil content
    assert_equal "", Detergent.text(EMPTY_PAGE)
    assert_equal "", Detergent.markdown(EMPTY_PAGE)
  end

  def test_real_articles_do_not_trigger_the_fallback
    fixture = File.read(File.expand_path("fixtures/coffee_article.html", __dir__))
    _title, content = Detergent.extract(fixture)

    refute_equal "ul", content.name
    assert_equal "main", content.name
  end
end
