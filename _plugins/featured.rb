require 'bibtex'

module Jekyll
  # Collects works, experiments and papers flagged `featured` into
  # site.data['featured'] for the home page, ordered by featured_order.
  class FeaturedGenerator < Generator
    safe true
    priority :lowest

    COLLECTIONS = { 'projects' => 'work', 'experiments' => 'experiment' }.freeze
    UNORDERED = 999

    def generate(site)
      items = collection_items(site) + bibliography_items(site)
      site.data['featured'] = items.sort_by { |i| [i['order'], i['title']] }
    end

    private

    def collection_items(site)
      COLLECTIONS.flat_map do |name, kind|
        docs = site.collections[name]&.docs || []
        docs.select { |d| truthy?(d.data['featured']) }.map { |d| doc_item(d, kind) }
      end
    end

    def doc_item(doc, kind)
      {
        'kind' => kind,
        'title' => doc.data['title'].to_s.sub(/\s*\(\d{4}\)\z/, ''),
        'url' => doc.data['redirect'] || doc.url,
        'img' => doc.data['img'],
        'meta' => (doc.data['meta'] || doc.data['year']).to_s,
        'description' => doc.data['description'],
        'order' => order(doc.data['featured_order']),
        'external' => false
      }
    end

    def bibliography_items(site)
      path = bibliography_path(site)
      return [] unless File.exist?(path)

      BibTeX.open(path).data
            .select { |e| e.is_a?(BibTeX::Entry) && truthy?(field(e, :featured)) }
            .map { |e| paper_item(e) }
    end

    def bibliography_path(site)
      scholar = site.config['scholar'] || {}
      dir = scholar.fetch('source', '_bibliography').sub(%r{\A/}, '')
      File.join(site.source, dir, scholar.fetch('bibliography', 'papers.bib'))
    end

    def paper_item(entry)
      {
        'kind' => 'paper',
        'title' => field(entry, :featured_title) || field(entry, :title),
        'url' => paper_url(entry),
        'img' => preview_path(field(entry, :preview)),
        'meta' => paper_meta(field(entry, :abbr), field(entry, :year)),
        'description' => field(entry, :featured_description),
        'order' => order(field(entry, :featured_order)),
        'external' => true
      }
    end

    def paper_url(entry)
      html = field(entry, :html)
      doi = field(entry, :doi)
      pdf = field(entry, :pdf)
      return html if html
      return "https://doi.org/#{doi.delete_prefix('https://doi.org/')}" if doi
      return pdf if pdf&.include?('://')
      return "/assets/pdf/#{pdf}" if pdf

      '/publications/'
    end

    def preview_path(preview)
      return nil unless preview

      preview.include?('://') ? preview : "/assets/img/publication_preview/#{preview}"
    end

    def paper_meta(abbr, year)
      return abbr if abbr && year && abbr.include?(year)

      [abbr, year].compact.join(' · ')
    end

    def field(entry, key)
      value = entry[key]
      return nil if value.nil?

      text = value.to_s.delete('{}').strip
      text.empty? ? nil : text
    end

    def truthy?(value)
      value == true || value.to_s.strip.casecmp?('true')
    end

    def order(value)
      value.to_s.match?(/\A\d+\z/) ? value.to_i : UNORDERED
    end
  end
end
