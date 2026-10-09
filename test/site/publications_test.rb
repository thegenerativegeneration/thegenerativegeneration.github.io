require_relative '../test_helper'

class PublicationsTest < Minitest::Test
  include SiteHelpers

  def pubs
    @pubs ||= page('/publications/')
  end

  def test_entries_use_pub_markup
    bib_entries = File.read(File.expand_path('../../_bibliography/papers.bib', __dir__)).scan(/^@\w+\{/).size
    assert_equal bib_entries, pubs.css('.bibliography > li .pub').size
    assert pubs.css('.pub__title').all? { |t| !t.text.strip.empty? }
  end

  def test_links_render_as_chips
    chips = pubs.css('.pub .chips a')
    refute_empty chips
    assert chips.all? { |a| a['class'].split.include?('chip') }
  end

  def test_doi_links_are_not_double_prefixed
    pubs.css('a[href*="doi.org"]').each { |a| refute_match(%r{doi\.org/https?://}, a['href']) }
  end

  def test_no_raw_latex_in_abstracts
    refute_match(/\\textit/, pubs.text)
  end

  def test_proceedings_periodical_has_no_leading_comma
    pubs.css('.pub__periodical').each { |p| refute_match(/\A\s*[,.]/, p.text) }
  end

  def test_author_list_has_no_space_before_commas
    pubs.css('.pub__authors').each { |a| refute_match(/\s,/, a.text.gsub(/\s+/, ' ')) }
  end

  def test_panel_toggles_are_keyboard_buttons
    toggles = pubs.css('.pub .chips .abstract, .pub .chips .bibtex, .pub .chips .award')
    refute_empty toggles
    toggles.each do |t|
      assert_equal 'button', t.name
      assert_equal 'false', t['aria-expanded']
    end
  end

  def test_filter_input_present
    assert pubs.at_css('input#bibsearch.bibsearch-form-input')
  end

  def test_no_icon_fonts_or_badges
    assert_empty pubs.css('i.fa-solid, .badges, .altmetric-embed')
  end
end
