require_relative '../test_helper'

class CleanupTest < Minitest::Test
  include SiteHelpers

  ROOT = File.expand_path('../..', __dir__)

  def test_no_icon_font_markup_anywhere
    all_html_files.each do |f|
      refute_match(/class="[^"]*\b(fa-[a-z]|ti ti-|ai ai-)/, File.read(f), f)
    end
  end

  def test_every_layout_and_include_is_used
    sources = Dir.glob(File.join(ROOT, '{_layouts,_includes,_pages,_posts,_projects,_experiments,_plugins}', '**', '*.{liquid,md,html,rb}'))
                 .map { |f| File.read(f) }.join("\n") + File.read(File.join(ROOT, '_config.yml'))
    Dir.glob(File.join(ROOT, '_includes', '**', '*.liquid')).each do |inc|
      name = inc.delete_prefix(File.join(ROOT, '_includes/'))
      assert_match(/include\s+#{Regexp.escape(name)}/, sources, "unused include #{name}")
    end
    Dir.glob(File.join(ROOT, '_layouts', '*.liquid')).each do |layout|
      name = File.basename(layout, '.liquid')
      assert_match(/(layout:\s*#{name}\b|bibliography_template:\s*#{name}\b|'layout'\s*=>\s*'#{name}')/, sources, "unused layout #{name}")
    end
  end

  def test_only_design_fonts_shipped
    fonts = Dir.glob(File.join(SITE_DIR, 'assets', '{fonts,webfonts}', '*')).map { |f| File.basename(f) }
    assert fonts.all? { |f| f.match?(/\A(pixelify-sans|jetbrains-mono|source-serif-4)-latin(-ext)?-\d{3}-(normal|italic)\.woff2\z/) }, fonts.inspect
  end

  def test_404_has_no_auto_redirect
    doc = page('/404.html')
    assert_nil doc.at_css('meta[http-equiv="refresh"]')
    assert doc.at_css('main a[href="/"]')
  end
end
