# frozen_string_literal: true

require_relative "test_helper"

class TestArticleBodies < Minitest::Test
  PROSE = "Making ink requires oak galls, water, and careful preparation. The recipe and its history deserve to be preserved in full. " * 3

  def test_prefers_story_body_over_a_large_page_with_widgets
    html = <<~HTML
      <title>Ink history</title>
      <div class="site-menu"><a href="/">Navigation</a></div>
      <div class="story-content"><h1>Ink history</h1>
        <div class="story-body"><p>#{PROSE}</p>
          <div class="insert-post-ads">Article continues after advertisement</div>
          <blockquote>Historical quotation.</blockquote>
          <ul><li>Keep this recipe step.</li></ul>
          <p><a href="/source">Source</a> and the final paragraph.</p>
          <div class="newsletter-signup">Subscribe now</div>
        </div>
        <div class="bio-container"><p>Author biography.</p></div>
      </div>
      <div class="sidebar-content-well">#{'<p>Daily news and recommendations.</p>' * 40}</div>
      <div class="related-stories">Recommended stories</div>
    HTML
    _, content = Detergent.extract(html)
    assert_includes content.text, PROSE.strip
    assert_includes content.text, 'Historical quotation.'
    assert_includes content.text, 'Keep this recipe step.'
    assert_includes content.text, 'the final paragraph.'
    %w[Navigation advertisement Subscribe biography Daily Recommended].each do |junk|
      refute_includes content.text, junk
    end
  end

  def test_ignores_a_body_marker_containing_mostly_links
    html = <<~HTML
      <div class="entry-content"><p><a href="/index">#{PROSE}</a></p></div>
      <article><h1>Real article</h1><p>#{PROSE}</p><p>Ending.</p></article>
    HTML
    _, content = Detergent.extract(html)
    assert_includes content.text, 'Ending.'
    refute content.at('a[href="/index"]')
  end

  def test_keeps_article_asides_and_does_not_match_ad_inside_other_words
    html = <<~HTML
      <article><p class="reading">#{PROSE}</p>
        <aside><p>Editorial explanation.</p></aside>
        <div class="shadow"><p>Additional article text.</p></div>
        <div hidden>Hidden promotion</div>
        <div style="display : none">Invisible promotion</div>
        <div role="navigation">Menu</div>
      </article>
    HTML
    _, content = Detergent.extract(html)
    assert_includes content.text, 'Editorial explanation.'
    assert_includes content.text, 'Additional article text.'
    refute_includes content.text, 'promotion'
    refute_includes content.text, 'Menu'
  end
end
