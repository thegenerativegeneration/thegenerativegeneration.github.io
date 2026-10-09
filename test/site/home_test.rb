require 'uri'
require_relative '../test_helper'

class HomeTest < Minitest::Test
  include SiteHelpers

  def home
    @home ||= page('/')
  end

  def test_hero_has_name_bio_and_links
    assert_equal 'Philipp Haslbauer', home.at_css('.hero h1.display-name').text.strip
    assert_includes home.at_css('.hero__bio').text, 'Lucerne'
    assert_equal %w[email instagram linkedin scholar cv], home.css('.hero .text-links a').map { |a| a.text.strip }
  end

  def test_email_link_is_obfuscated_mailto
    href = home.css('.hero .text-links a').find { |a| a.text.strip == 'email' }['href']
    assert href.start_with?('mailto:')
    assert_equal 'i@philipphaslbauer.com', URI.decode_www_form_component(href.delete_prefix('mailto:'))
    refute_includes File.read(File.join(SITE_DIR, 'index.html')), 'i@philipphaslbauer.com'
  end

  def test_featured_cards_in_order
    cards = home.css('.featured .card-item')
    assert_equal %w[work paper experiment], cards.map { |c| c.at_css('.badge-kind').text.strip }
    assert_equal ['Deus in Machina', 'VR Planica', 'Voice Puppetry'], cards.map { |c| c.at_css('.card-item__title').text.strip }
    assert_equal '/works/deus-in-machina/', cards[0].at_css('a')['href']
    assert_equal '_blank', cards[1].at_css('a')['target']
  end

  def test_cv_is_not_on_home
    assert_nil home.at_css('.cv')
  end
end
