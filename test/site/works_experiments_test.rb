require_relative '../test_helper'

class WorksExperimentsTest < Minitest::Test
  include SiteHelpers

  def test_works_shows_only_non_empty_categories
    labels = page('/works/').css('.work-category .section-label').map { |h| h.text.strip }
    assert_equal ['exhibited'], labels
  end

  def test_works_card_links_to_work_page
    assert_equal '/works/deus-in-machina/', page('/works/').at_css('.card-item a')['href']
  end

  def test_work_page_marks_works_nav_active
    assert_equal 'works', page('/works/deus-in-machina/').at_css('#site-nav a.active').text.strip
  end

  def test_experiments_lists_all_visible_experiments
    titles = page('/experiments/').css('.card-item__title').map { |t| t.text.strip }
    assert_equal 3, titles.size
    assert_includes titles, 'Morse Chatbot'
    refute_includes titles, 'The Scriptorium'
  end

  def test_experiment_cards_do_not_use_generated_srcset
    card = page('/experiments/').css('.card-item').find { |c| c.at_css('.card-item__title').text.include?('Morse') }
    assert_equal '/assets/experiments/morse-chatbot/preview.png', card.at_css('img')['src']
    assert_nil card.at_css('source')
  end

  def test_experiment_page_embeds_iframe
    assert page('/experiments/morse-chatbot/').at_css('iframe[src="/assets/experiments/morse-chatbot/index.html"]')
  end
end
