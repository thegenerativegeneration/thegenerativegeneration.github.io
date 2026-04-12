require 'json'
require 'find'
require 'pathname'

module Jekyll
  # Serves a single file from outside the normal Jekyll source tree.
  class ExperimentStaticFile < StaticFile
    def initialize(site, abs_src, dest_dir, name)
      super(site, site.source, dest_dir, name)
      @abs_src = abs_src
    end

    def path
      @abs_src
    end
  end

  class ExperimentsGenerator < Generator
    safe true
    priority :normal

    EXPERIMENTS_SRC = '_experiments_src/public'

    def generate(site)
      src_dir = File.join(site.source, EXPERIMENTS_SRC)
      unless File.directory?(src_dir)
        Jekyll.logger.warn 'ExperimentsGenerator:', "source dir not found: #{src_dir}"
        return
      end

      Dir.glob(File.join(src_dir, '*')).select { |f| File.directory?(f) }.sort.each do |exp_dir|
        name = File.basename(exp_dir)
        meta = read_meta(exp_dir)

        add_experiment_doc(site, name, meta)
        add_static_files(site, exp_dir, name)

        Jekyll.logger.info 'ExperimentsGenerator:', "registered experiment '#{name}'"
      end
    end

    private

    def read_meta(dir)
      meta_path = File.join(dir, 'meta.json')
      return {} unless File.exist?(meta_path)

      JSON.parse(File.read(meta_path))
    rescue JSON::ParserError => e
      Jekyll.logger.warn 'ExperimentsGenerator:', "bad meta.json in #{dir}: #{e.message}"
      {}
    end

    def add_experiment_doc(site, name, meta)
      title = meta['title'] || name.gsub('-', ' ').split.map(&:capitalize).join(' ')

      path = site.in_source_dir("_experiments/#{name}.md")
      doc  = Jekyll::Document.new(path, site: site, collection: site.collections['experiments'])
      doc.data.merge!(
        'title'       => title,
        'description' => meta['description'] || '',
        'importance'  => meta['importance'] || 99,
        'year'        => meta['year'] || '',
        'layout'      => 'experiment',
        'experiment'  => name,
        'permalink'   => "/experiments/#{name}/",
        'img'         => meta['img'] || nil,
      )
      doc.content = meta['description'] || ''
      site.collections['experiments'].docs << doc
    end

    def add_static_files(site, exp_dir, name)
      exp_pathname = Pathname.new(exp_dir)

      Find.find(exp_dir) do |abs_path|
        next unless File.file?(abs_path)

        relative  = Pathname.new(abs_path).relative_path_from(exp_pathname).to_s
        file_name = File.basename(relative)
        sub_dir   = File.dirname(relative)
        dest_dir  = sub_dir == '.' ? "/assets/experiments/#{name}" : "/assets/experiments/#{name}/#{sub_dir}"

        site.static_files << ExperimentStaticFile.new(site, abs_path, dest_dir, file_name)
      end
    end
  end
end
