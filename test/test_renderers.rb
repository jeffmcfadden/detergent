# frozen_string_literal: true

require_relative "test_helper"

class TestRenderers < Minitest::Test
  def markdown(html)
    Detergent::MarkdownRenderer.new.render(Nokogiri::HTML5.fragment(html))
  end

  def text(html)
    Detergent::TextRenderer.new.render(Nokogiri::HTML5.fragment(html))
  end

  def test_markdown_headings
    assert_equal "## Section Title", markdown("<h2>Section Title</h2>")
  end

  def test_markdown_paragraphs_are_separated_and_whitespace_collapsed
    input = "<p>First\n  paragraph.</p><p>Second paragraph.</p>"
    assert_equal "First paragraph.\n\nSecond paragraph.", markdown(input)
  end

  def test_markdown_links_and_inline_styles
    input = "<p>See <a href='https://example.com'>this <strong>bold</strong></a> and <em>that</em> and <code>x = 1</code>.</p>"
    assert_equal "See [this **bold**](https://example.com) and *that* and `x = 1`.", markdown(input)
  end

  def test_markdown_lists
    assert_equal "- One\n- Two", markdown("<ul><li>One</li><li>Two</li></ul>")
    assert_equal "1. One\n2. Two", markdown("<ol><li>One</li><li>Two</li></ol>")
  end

  def test_markdown_blockquote
    assert_equal "> Wise words\n> here.", markdown("<blockquote><p>Wise words<br>here.</p></blockquote>")
  end

  def test_markdown_preformatted_preserves_whitespace
    assert_equal "```\ndef foo\n  1\nend\n```", markdown("<pre>def foo\n  1\nend</pre>")
  end

  def test_markdown_figure_with_caption
    input = "<figure><img src='/cat.jpg' alt='A cat'><figcaption>The cat</figcaption></figure>"
    assert_equal "![A cat](/cat.jpg)\n\n*The cat*", markdown(input)
  end

  def test_markdown_table
    input = "<table><tr><th>Name</th><th>Age</th></tr><tr><td>Ada</td><td>36</td></tr></table>"
    assert_equal "| Name | Age |\n| --- | --- |\n| Ada | 36 |", markdown(input)
  end

  def test_text_strips_markdown_syntax
    input = "<h2>Title</h2><p>See <a href='https://example.com'>this</a>, <strong>bold</strong>, <code>x = 1</code>.</p>"
    assert_equal "Title\n\nSee this, bold, x = 1.", text(input)
  end

  def test_text_drops_images_but_keeps_captions
    input = "<figure><img src='/cat.jpg' alt='A cat'><figcaption>The cat</figcaption></figure><p>After.</p>"
    assert_equal "The cat\n\nAfter.", text(input)
  end

  def test_text_keeps_list_structure
    assert_equal "- One\n- Two", text("<ul><li>One</li><li>Two</li></ul>")
  end
end
