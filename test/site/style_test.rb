require_relative '../test_helper'

class StyleTest < Minitest::Test
  include SiteHelpers

  TOKENS = {
    '--bg' => '#07110b', '--text' => '#cfe6d2', '--head' => '#c6f7bd',
    '--accent' => '#ff7ac2', '--muted' => '#86a08c', '--rule' => '#26402e'
  }.freeze
  FONT_FILES = %w[pixelify-sans-latin-500-normal jetbrains-mono-latin-400-normal source-serif-4-latin-400-normal].freeze

  def test_palette_tokens_are_defined
    TOKENS.each { |name, value| assert_match(/#{Regexp.escape(name)}:\s*#{value}/i, css, name) }
  end

  def test_fonts_are_self_hosted
    all_html_files.each { |f| refute_match(/fonts\.googleapis\.com/, File.read(f), f) }
    FONT_FILES.each do |name|
      assert File.exist?(File.join(SITE_DIR, "assets/fonts/#{name}.woff2")), name
      assert_includes css, "#{name}.woff2"
    end
  end

  def test_no_light_theme_or_icon_font_css
    refute_match(/prefers-color-scheme:\s*light|data-theme/, css)
    refute_match(/font-family:\s*["']?(Font Awesome|tabler-icons|Academicons)/i, css)
  end

  def test_focus_style_survives_purge
    assert_match(/:focus-visible\{outline:2px solid var\(--accent\)/, css)
  end

  def test_footer_is_static_and_has_links
    footer = page('/').at_css('footer.site-footer')
    assert footer
    refute_match(/fixed/, footer['class'])
    assert_equal %w[email instagram linkedin scholar cv], footer.css('.text-links a').map { |a| a.text.strip }
  end

  def test_nav_marks_current_section
    link = page('/publications/').at_css('#site-nav a.active')
    assert_equal 'publications', link.text.strip
    assert_equal 'page', link['aria-current']
  end

  def test_nav_order
    labels = page('/blog/').css('#site-nav .nav-link').map { |a| a.text.strip }
    assert_equal %w[about works publications experiments blog], labels
  end
end
