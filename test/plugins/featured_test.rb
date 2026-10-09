require 'minitest/autorun'
require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../../_plugins/featured'

class FeaturedGeneratorTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def write(path, body)
    full = File.join(@dir, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.write(full, body)
  end

  def doc(collection, name, front_matter)
    write("_#{collection}/#{name}.md", "#{front_matter.to_yaml}---\nbody\n")
  end

  def featured
    config = Jekyll.configuration(
      'source' => @dir, 'destination' => File.join(@dir, '_site'), 'quiet' => true,
      'collections' => { 'projects' => { 'output' => true }, 'experiments' => { 'output' => true } },
      'scholar' => { 'source' => '/_bibliography/', 'bibliography' => 'papers.bib' }
    )
    site = Jekyll::Site.new(config)
    site.read
    Jekyll::FeaturedGenerator.new(site.config).generate(site)
    site.data['featured']
  end

  def test_returns_empty_list_when_nothing_is_featured
    doc('projects', 'a', 'title' => 'A')
    assert_equal [], featured
  end

  def test_sorts_across_kinds_by_featured_order
    doc('projects', 'deus', 'title' => 'Deus in Machina (2024)', 'featured' => true, 'featured_order' => 1,
                            'meta' => '2024–2026 · Lucerne', 'img' => '/assets/img/d.jpg')
    doc('experiments', 'two', 'title' => 'Voice Puppetry (2023)', 'featured' => true, 'year' => 2023)
    write('_bibliography/papers.bib', <<~BIB)
      @inproceedings{p1, title={ VR Planica: Long }, featured={true}, featured_order={2},
        featured_title={VR Planica}, abbr={IMX 2025}, year={2025}, doi={10.1/x}, preview={planica.jpg}}
    BIB
    items = featured
    assert_equal %w[work paper experiment], items.map { |i| i['kind'] }
    assert_equal ['Deus in Machina', 'VR Planica', 'Voice Puppetry'], items.map { |i| i['title'] }
    assert_equal '2024–2026 · Lucerne', items[0]['meta']
    assert_equal 'IMX 2025', items[1]['meta']
    assert_equal '2023', items[2]['meta']
    assert_equal '/assets/img/publication_preview/planica.jpg', items[1]['img']
    assert_equal 999, items[2]['order']
  end

  def test_paper_url_prefers_html_then_doi_then_pdf
    write('_bibliography/papers.bib', <<~BIB)
      @article{a, title={A}, featured={true}, year={2024}, html={https://h.example}, doi={10.1/a}}
      @article{b, title={B}, featured={true}, year={2024}, doi={10.1/b}, pdf={b.pdf}}
      @article{c, title={C}, featured={true}, year={2024}, pdf={c.pdf}}
    BIB
    urls = featured.to_h { |i| [i['title'], i['url']] }
    assert_equal 'https://h.example', urls['A']
    assert_equal 'https://doi.org/10.1/b', urls['B']
    assert_equal '/assets/pdf/c.pdf', urls['C']
  end

  def test_paper_without_preview_has_no_image
    write('_bibliography/papers.bib', "@article{a, title={A}, featured={true}, year={2024}}\n")
    item = featured.first
    assert_nil item['img']
    assert_equal '2024', item['meta']
    assert item['external']
  end

  def test_unflagged_paper_is_ignored
    write('_bibliography/papers.bib', "@article{a, title={A}, year={2024}}\n")
    assert_equal [], featured
  end
end
