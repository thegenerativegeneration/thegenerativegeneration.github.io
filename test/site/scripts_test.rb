require_relative '../test_helper'

class ScriptsTest < Minitest::Test
  include SiteHelpers

  ALLOWED_LOCAL = %w[bootstrap.bundle.min.js common.js bibsearch.js].freeze
  ALLOWED_EXTERNAL = [
    %r{\Ahttps://cdn\.jsdelivr\.net/npm/jquery@3\.6\.0/dist/jquery\.min\.js\z},
    %r{\Ahttps://unpkg\.com/es-module-shims@},
    %r{\Ahttps://unpkg\.com/@splinetool/viewer@} # embedded in the 3DGS blog post
  ].freeze

  def script_srcs(file)
    Nokogiri::HTML(File.read(file)).css('script[src]').map { |s| s['src'] }
  end

  def test_pages_load_only_allowed_local_scripts
    all_html_files.each do |file|
      script_srcs(file).select { |s| s.start_with?('/assets/js/') }.each do |src|
        assert_includes ALLOWED_LOCAL, File.basename(src.split('?').first), "#{file} loads #{src}"
      end
    end
  end

  def test_pages_load_only_allowed_external_scripts
    all_html_files.each do |file|
      script_srcs(file).reject { |s| s.start_with?('/') }.each do |src|
        assert ALLOWED_EXTERNAL.any? { |re| re.match?(src) }, "#{file} loads #{src}"
      end
    end
  end

  def test_nothing_references_removed_theme_toggle
    (Dir.glob(File.join(SITE_DIR, 'assets/js/**/*.js')) + all_html_files).each do |f|
      refute_match(/determineComputedTheme/, File.read(f), f)
    end
  end
end
