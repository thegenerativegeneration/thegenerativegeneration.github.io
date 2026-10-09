require 'digest/md5'

module Jekyll
  # Liquid filters that append a content hash to asset URLs, so browsers
  # fetch a new copy whenever the underlying source changes.
  module CacheBust
    # Hash of the asset file itself, e.g. "/assets/js/common.js?<md5>".
    def bust_file_cache(file_name)
      path = File.join(site_source, file_name.slice(file_name.index('assets/')..-1))
      "#{file_name}?#{Digest::MD5.hexdigest(File.read(path))}"
    end

    # Hash of every Sass partial plus the main stylesheet entry point, because
    # the compiled main.css does not exist yet while pages render.
    def bust_css_cache(file_name)
      sources = Dir.glob(File.join(site_source, '_sass', '**', '*.scss')).sort
      sources << File.join(site_source, 'assets', 'css', 'main.scss')
      "#{file_name}?#{Digest::MD5.hexdigest(sources.map { |f| File.read(f) }.join)}"
    end

    private

    def site_source
      @context.registers[:site].source
    end
  end
end

Liquid::Template.register_filter(Jekyll::CacheBust)
