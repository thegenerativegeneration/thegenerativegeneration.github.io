require 'minitest/autorun'
require 'nokogiri'

SITE_DIR = File.expand_path('../_site', __dir__)

module SiteHelpers
  def page(path)
    file = File.join(SITE_DIR, path)
    file = File.join(file, 'index.html') if File.directory?(file)
    assert File.exist?(file), "missing built page #{path}"
    Nokogiri::HTML(File.read(file))
  end

  def all_html_files
    Dir.glob(File.join(SITE_DIR, '**', '*.html')).reject { |f| f.start_with?(File.join(SITE_DIR, 'assets')) }
  end

  def css
    @css ||= File.read(File.join(SITE_DIR, 'assets', 'css', 'main.css'))
  end
end
