require 'minitest/autorun'
require 'jekyll'
require 'tmpdir'
require 'nokogiri'

class CardIncludeTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)

  def render(markup)
    Dir.mktmpdir do |dir|
      File.symlink(File.join(ROOT, '_includes'), File.join(dir, '_includes'))
      config = Jekyll.configuration('source' => dir, 'destination' => File.join(dir, '_site'), 'quiet' => true)
      site = Jekyll::Site.new(config)
      html = Liquid::Template.parse(markup).render!(site.site_payload, registers: { site: site, page: {} })
      Nokogiri::HTML.fragment(html)
    end
  end

  def test_card_without_image_renders_placeholder
    card = render('{% include card.liquid title="No Image" url="/x/" %}')
    assert card.at_css('.card-item__img--empty')
    assert_nil card.at_css('img')
    assert_equal '/x/', card.at_css('a')['href']
  end

  def test_external_card_opens_in_new_tab
    card = render('{% include card.liquid title="P" url="https://example.org/p" external=true %}')
    assert_equal '_blank', card.at_css('a')['target']
    assert_equal 'https://example.org/p', card.at_css('a')['href']
  end

  def test_empty_meta_is_omitted
    assert_nil render('{% include card.liquid title="T" url="/t/" meta="" %}').at_css('.card-item__meta')
  end
end
