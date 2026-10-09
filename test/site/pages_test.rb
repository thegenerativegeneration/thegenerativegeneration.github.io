require_relative '../test_helper'

class PagesTest < Minitest::Test
  include SiteHelpers

  EXPECTED = %w[
    /404.html /index.html /works/index.html /works/deus-in-machina/index.html
    /publications/index.html /experiments/index.html /experiments/one/index.html
    /experiments/two/index.html /experiments/morse-chatbot/index.html /blog/index.html
    /blog/2023/controlling-diffusion/index.html /blog/2024/easy-3dgs/index.html /cv/index.html
  ].freeze
  EXTERNAL_POST = %r{\A/blog/\d{4}/[^/]+/index\.html\z}

  def built_pages
    all_html_files.map { |f| f.delete_prefix(SITE_DIR) }
  end

  def test_all_expected_pages_exist
    assert_empty EXPECTED - built_pages
  end

  def test_no_unexpected_pages
    extra = (built_pages - EXPECTED).reject { |p| EXTERNAL_POST.match?(p) }
    assert_empty extra
  end
end
