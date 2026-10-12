require 'yaml'
require_relative '../test_helper'

class CvTest < Minitest::Test
  include SiteHelpers

  def cv
    @cv ||= page('/cv/')
  end

  def data
    YAML.load_file(File.expand_path('../../_data/cv.yml', __dir__))
  end

  def test_every_section_and_entry_is_rendered
    sections = data.reject { |s| s['type'] != 'bibliography' && (s['contents'].nil? || s['contents'].empty?) }
    assert_equal sections.map { |s| s['title'] }, cv.css('.cv-section > .section-label').map { |h| h.text.strip }
    assert_equal sections.sum { |s| s['contents']&.size.to_i }, cv.css('.cv-section:not(.cv-section--bib) .cv-entry').size
  end

  def test_publications_come_from_bibliography
    entries = cv.css('.cv-section--bib .cv-entry')
    refute_empty entries
    assert entries.all? { |e| e.at_css('.pub__self') }, 'every publication highlights the site owner'
    years = entries.map { |e| e.at_css('.cv-entry__year').text.to_i }
    assert_equal years.sort.reverse, years
  end

  def test_string_and_list_descriptions_both_render
    assert cv.css('.cv-entry__items li').any?
    assert cv.css('.cv-entry__desc').any? { |p| p.text.include?('Watch here') }
  end

  def test_print_button_and_print_styles
    assert_equal 'window.print()', cv.at_css('button.cv-print')['onclick']
    assert_match(/@media print/, css)
    assert_match(/break-inside:\s*avoid/, css)
  end

  def test_no_icon_markup
    assert_empty cv.css('i[class*="fa-"]')
  end
end
