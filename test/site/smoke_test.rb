require_relative '../test_helper'

class SmokeTest < Minitest::Test
  include SiteHelpers

  def test_home_page_is_built_with_site_title
    assert_equal 'Philipp Haslbauer', page('/').at_css('title').text.strip
  end
end
