# frozen_string_literal: true

require_relative "test_helper"

# End-to-end extraction tests against a realistic saved page, so the
# heuristics can't silently regress during refactoring.
class TestFixtureExtraction < Minitest::Test
  FIXTURE = File.read(File.expand_path("fixtures/coffee_article.html", __dir__))

  def setup
    @cleaner = Detergent::Cleaner.new
    @cleaned = @cleaner.clean(FIXTURE)
  end

  def test_extracts_title
    assert_includes @cleaner.title(FIXTURE), "How to Brew Better Coffee at Home"
  end

  def test_keeps_article_text
    assert_includes @cleaned, "Freshness is the single biggest lever."
    assert_includes @cleaned, "Grind consistency comes second."
    assert_includes @cleaned, "Finally, water temperature."
  end

  def test_keeps_article_media_and_structure
    assert_includes @cleaned, "/images/pourover.jpg"
    assert_includes @cleaned, "A steady, even pour matters more than the brand of the dripper."
    assert_includes @cleaned, "Buy a burr grinder before you buy anything else."
    assert_includes @cleaned, "Grind with a burr grinder just before brewing."
  end

  def test_keeps_aside_within_article
    assert_includes @cleaned, "Editor's note: this guide focuses on technique"
  end

  def test_removes_scripts_styles_and_ads
    refute_includes @cleaned, "trackPageView"
    refute_includes @cleaned, "font-family: sans-serif"
    refute_includes @cleaned, "Special offer: subscribe now"
  end

  def test_removes_navigation_and_chrome
    refute_includes @cleaned, ">Reviews<"
    refute_includes @cleaned, "/logo.png"
    refute_includes @cleaned, "All rights reserved"
  end

  def test_removes_sidebar_and_comments
    refute_includes @cleaned, "Popular Posts"
    refute_includes @cleaned, "The Best Grinders of 2026"
    refute_includes @cleaned, "Great post!"
    refute_includes @cleaned, "What about cold brew?"
  end

  def test_strips_junk_attributes_from_content
    refute_includes @cleaned, "class="
    refute_includes @cleaned, "style="
    refute_includes @cleaned, "onclick="
    refute_includes @cleaned, "data-track="
  end

  def test_keeps_id_attributes_for_anchors
    assert_includes @cleaned, 'id="conclusion"'
  end
end
