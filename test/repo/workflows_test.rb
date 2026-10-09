require 'minitest/autorun'
require 'yaml'

class WorkflowsTest < Minitest::Test
  WORKFLOWS = Dir.glob(File.expand_path('../../.github/workflows/*.yml', __dir__))

  def steps(file)
    YAML.load_file(file)['jobs'].values.flat_map { |job| job['steps'] || [] }
  end

  def test_ruby_version_comes_from_ruby_version_file
    WORKFLOWS.each do |file|
      steps(file).select { |s| s['uses'].to_s.start_with?('ruby/setup-ruby') }.each do |step|
        refute (step['with'] || {}).key?('ruby-version'), "#{File.basename(file)} pins ruby-version"
      end
    end
  end

  def test_checkouts_include_the_experiments_submodule
    WORKFLOWS.each do |file|
      steps(file).select { |s| s['uses'].to_s.start_with?('actions/checkout') }.each do |step|
        assert_equal 'recursive', (step['with'] || {})['submodules'], "#{File.basename(file)} checkout without submodules"
      end
    end
  end

  def test_no_steps_for_removed_features
    WORKFLOWS.each { |file| refute_match(/giscus|jupyter|nbconvert/, File.read(file), File.basename(file)) }
  end

  def test_lychee_can_resolve_root_relative_links
    WORKFLOWS.each do |file|
      steps(file).select { |s| s['uses'].to_s.start_with?('lycheeverse/lychee-action') }.each do |step|
        assert_match(/--root-dir/, step.dig('with', 'args').to_s, "#{File.basename(file)} lychee without --root-dir")
      end
    end
  end
end
