require 'html-proofer'

HTMLProofer.check_directory(
  File.expand_path('../_site', __dir__),
  checks: %w[Links Images Scripts],
  disable_external: true,
  enforce_https: false,
  allow_missing_href: true,
  ignore_files: [%r{/_site/assets/}]
).run
