# frozen_string_literal: true

require_relative "test_helper"

class TestInspector < Minitest::Test
  COFFEE = File.read(File.expand_path("fixtures/coffee_article.html", __dir__))
  HN = File.read(File.expand_path("fixtures/hn_front_page.html", __dir__))

  def test_article_report
    report = Detergent::Inspector.new.analyze(COFFEE)

    assert report.located?
    assert_operator report.best_score, :>=, Detergent::ContentLocator::MINIMUM_CONTENT_SCORE
    assert_equal "main", report.content_root
    assert_operator report.content_root_size, :>, 1000
  end

  def test_article_report_records_removals_by_pass
    report = Detergent::Inspector.new.analyze(COFFEE)

    first_pass = report.removals[:first_pass]
    # The nav is inside the header, which is removed whole (no descent
    # into pruned subtrees), so header appears here rather than nav.
    assert_includes first_pass, "header"
    assert_includes first_pass, "footer"
    assert_includes first_pass, "script"

    second_pass = report.removals[:second_pass]
    assert_includes second_pass, "aside"   # the sidebar
    assert_includes second_pass, "section" # the comments
  end

  def test_top_nodes_include_score_breakdowns
    report = Detergent::Inspector.new.analyze(COFFEE)

    top = report.top_nodes.first
    assert_operator top.score, :>, 0
    refute_nil top.breakdown
    assert(top.breakdown.any? { |label, _points| label.include?("paragraph") })
    assert(top.breakdown.all? { |_label, points| points.is_a?(Integer) })
  end

  def test_report_renders_as_text
    output = Detergent::Inspector.new.analyze(COFFEE).to_s

    assert_includes output, "Verdict: article content located"
    assert_includes output, "Top scoring nodes"
    assert_includes output, "Content root: main"
    assert_includes output, "First pass"
    assert_includes output, "Second pass"
  end

  def test_article_report_shows_article_strategy
    report = Detergent::Inspector.new.analyze(COFFEE)

    assert_equal :article, report.strategy
    assert_includes report.to_s, "article content located"
  end

  def test_link_list_fallback_report
    report = Detergent::Inspector.new.analyze(HN)

    assert_equal :link_list, report.strategy
    assert_operator report.best_score, :<, Detergent::ContentLocator::MINIMUM_CONTENT_SCORE
    assert_includes report.to_s, "extracted link list instead"
    assert_includes report.to_s, "Content root: ul"
  end

  def test_no_content_report
    html = "<html><head><title>Nothing</title></head><body><p>Hi.</p></body></html>"
    report = Detergent::Inspector.new.analyze(html)

    refute report.located?
    assert_nil report.strategy
    assert_includes report.to_s, "NO MAIN CONTENT"
    assert_includes report.to_s, "Content root: (none)"
  end

  def test_cli_smoke
    fixture = File.expand_path("fixtures/coffee_article.html", __dir__)
    exe = File.expand_path("../exe/detergent", __dir__)
    lib = File.expand_path("../lib", __dir__)

    title = IO.popen([RbConfig.ruby, "-I", lib, exe, "--format", "title", fixture], &:read)
    assert_includes title, "How to Brew Better Coffee at Home"

    debug = IO.popen([RbConfig.ruby, "-I", lib, exe, "--format", "debug", fixture], &:read)
    assert_includes debug, "Verdict: article content located"
  end
end
