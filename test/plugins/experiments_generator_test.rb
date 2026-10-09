require 'minitest/autorun'
require 'jekyll'
require 'tmpdir'
require 'fileutils'
require_relative '../../_plugins/experiments_generator'

class ExperimentsGeneratorTest < Minitest::Test
  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@dir)
  end

  def add_experiment(name, meta_json)
    exp = File.join(@dir, '_experiments_src', 'public', name)
    FileUtils.mkdir_p(exp)
    File.write(File.join(exp, 'index.html'), '<p>x</p>')
    File.write(File.join(exp, 'meta.json'), meta_json) if meta_json
  end

  def generate(extra_config = {})
    config = Jekyll.configuration({
      'source' => @dir, 'destination' => File.join(@dir, '_site'), 'quiet' => true,
      'collections' => { 'experiments' => { 'output' => true } }
    }.merge(extra_config))
    site = Jekyll::Site.new(config)
    Jekyll::ExperimentsGenerator.new(site.config).generate(site)
    site
  end

  def titles(site)
    site.collections['experiments'].docs.map { |d| d.data['title'] }
  end

  def test_registers_experiment_from_valid_meta
    add_experiment('morse', '{"title": "Morse Chatbot", "year": 2026}')
    assert_equal ['Morse Chatbot'], titles(generate)
  end

  def test_invalid_meta_fails_the_build
    add_experiment('broken', "{\"title\": \"Broken\",\n}")
    error = assert_raises(Jekyll::Errors::FatalException) { generate }
    assert_includes error.message, 'broken'
  end

  def test_excluded_experiment_is_skipped_with_its_files
    add_experiment('keep', '{"title": "Keep"}')
    add_experiment('hide', '{"title": "Hide"}')
    site = generate('experiments_exclude' => ['hide'])
    assert_equal ['Keep'], titles(site)
    refute site.static_files.any? { |f| f.destination_rel_dir.include?('/hide') }
  end
end
