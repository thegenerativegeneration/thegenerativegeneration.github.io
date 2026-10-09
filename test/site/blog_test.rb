require_relative '../test_helper'

class BlogTest < Minitest::Test
  include SiteHelpers

  def test_blog_lists_posts_as_rows
    rows = page('/blog/').css('.row-list > .row-item')
    assert_operator rows.size, :>=, 3
    assert rows.all? { |r| r.at_css('.row-item__title a') }
  end

  def test_substack_items_are_marked_and_open_externally
    row = page('/blog/').css('.row-item').find { |r| r.at_css('.chip')&.text&.include?('substack') }
    assert row, 'expected at least one Substack row'
    assert_match %r{\Ahttps://}, row.at_css('.row-item__title a')['href']
    assert_equal '_blank', row.at_css('.row-item__title a')['target']
  end

  def test_no_tag_or_category_links
    assert_empty page('/blog/').css('a[href*="/blog/tag/"], a[href*="/blog/category/"]')
  end

  def test_post_has_toc_before_body_and_reading_width
    post = page('/blog/2023/controlling-diffusion/')
    assert post.at_css('article.prose nav.toc ul')
    assert post.at_css('.page-header .meta').text.include?('min read')
  end

  def test_code_is_highlighted_with_dark_theme
    assert page('/blog/2023/controlling-diffusion/').at_css('.highlight')
    assert_match(/\.highlight/, css)
  end
end
