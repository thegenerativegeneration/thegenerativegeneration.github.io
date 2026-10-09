# Site Cleanup and Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Strip the al-folio fork down to what philipphaslbauer.com uses, fix the live-site defects, and apply the approved visual system (layout A, type C, palette B3).

**Architecture:** Jekyll site, built by GitHub Actions and deployed to GitHub Pages from `main`. Bootstrap 4 CSS/JS stays for grid and nav collapse; every other theme layer is replaced by small Liquid templates and focused Sass partials driven by CSS custom properties. Two Ruby generators feed templates: `ExperimentsGenerator` (existing) and a new `FeaturedGenerator` that builds `site.data['featured']`. Tests are Minitest files that run against the built `_site` (Nokogiri) plus plugin unit tests, and html-proofer for internal links and images.

**Tech Stack:** Ruby 4.0.5, Jekyll 4, jekyll-scholar + bibtex-ruby, Dart Sass (`@use`), Minitest 6, Nokogiri, html-proofer 5, Playwright MCP for visual review.

**Spec:** `docs/superpowers/specs/2026-10-09-site-cleanup-redesign-design.md`

## Global Constraints

- Branch `redesign`. Never push to `main`; merging needs Philipp's explicit approval (pushing `main` deploys).
- Dark only. No theme toggle, no `prefers-color-scheme: light` styles.
- Palette tokens, exact values: `--bg #07110b`, `--text #cfe6d2`, `--head #c6f7bd`, `--accent #ff7ac2`, `--muted #86a08c`, `--rule #26402e`, `--glow 0 0 8px rgba(198,247,189,.35)` (glow on name and page titles only).
- Fonts: Pixelify Sans 500 (display), JetBrains Mono 400/500 (structure), Source Serif 4 400/400i/600 (body); self-hosted woff2, no request to `fonts.googleapis.com`.
- In-text links in `--accent`; nav links, card titles and text-link lists in `--head`.
- Content max-width 1100px, prose measure 68ch, side gutter 20px under 576px.
- No new JavaScript dependencies. Allowed external scripts: jQuery 3.6.0 from jsDelivr, es-module-shims on demo pages.
- No source file over ~300 lines among new Sass partials; no file over 500 lines anywhere we touch.
- Comments describe code, never history.
- Minitest suites must pass at the end of every task. html-proofer must be fully clean from Task 11 onward; before that, a failure is allowed only if it is in the Task 1 baseline or caused by blog tag/year links that Task 11 removes, and each such failure is listed in `LOG.md`.
- Every task ends with a commit on `redesign`. Commit messages: imperative, no prefix convention required.
- Decisions and findings are appended to `/Volumes/T7 Shield/Temp/website-redesign/LOG.md`.

## Review Focus

1. **Experiment previews outside `assets/img/`** (e.g. `/assets/experiments/morse-chatbot/preview.png`) must render without an ImageMagick `srcset`, which would point at non-existent `-480.webp` files. Pinned by `test_experiment_cards_do_not_use_generated_srcset` in Task 9.
2. **Long titles and author lists at 390px** (e.g. "Affordable Workflows for Volumetric Video Applications in XR…", eight authors) must not cause horizontal scrolling. Pinned by the overflow sweep in Task 13, Step 5.
3. **No featured items** must hide the "Selected" heading instead of rendering an empty section. Pinned by `test_returns_empty_list_when_nothing_is_featured` (Task 7) and the guard check in Task 8, Step 7.
4. **Featured paper without a `preview`** must render a placeholder block, not a broken image. Pinned by `test_paper_without_preview_has_no_image` (Task 7) and `test_card_without_image_renders_placeholder` in `test/includes/card_test.rb` (Task 8).
5. **Email link** must stay a working `mailto:` while its address is not present in plain text in the HTML. Pinned by `test_email_link_is_obfuscated_mailto` (Task 8).

---

## File map

| Path | Responsibility | Task |
|---|---|---|
| `.ruby-version`, `Gemfile`, `Gemfile.lock`, `.gitignore` | toolchain pin, test gems | 1 |
| `.github/workflows/deploy.yml` | build, test, purge CSS, deploy | 1 |
| `bin/check`, `test/test_helper.rb`, `test/proof.rb`, `test/site/*_test.rb`, `test/plugins/*_test.rb` | verification | 1+ |
| `_plugins/experiments_generator.rb` | experiments from submodule, strict meta, exclude list | 2 |
| `_layouts/default.liquid`, `_includes/head.liquid`, `_includes/scripts.liquid`, `assets/js/common.js` | page shell and the only runtime JS | 4 |
| `_config.yml` | pruned configuration | 5 |
| `assets/fonts/*.woff2`, `assets/css/main.scss`, `_sass/_*.scss` | design system | 6 |
| `_includes/header.liquid`, `_includes/footer.liquid`, `_includes/links.liquid` | site chrome | 6 |
| `_plugins/featured.rb` | `site.data['featured']` | 7 |
| `_includes/card.liquid`, `_layouts/home.liquid`, `_pages/about.md` | home | 8 |
| `_pages/projects.md`, `_pages/experiments.md`, `_layouts/page.liquid`, `_layouts/experiment.liquid`, `_layouts/demo.liquid` | works and experiments | 9 |
| `_layouts/bib.liquid`, `_includes/bib_search.liquid`, `_bibliography/papers.bib` | publications | 10 |
| `_pages/blog.md`, `_layouts/post.liquid`, `_includes/pagination.liquid`, `_sass/_code.scss` | blog | 11 |
| `_layouts/cv.liquid`, `_pages/cv.md`, `_sass/_cv.scss`, `_sass/_print.scss` | CV | 12 |
| `README.md`, `_pages/404.md`, deletions | final cleanup | 13 |

---

### Task 1: Toolchain pin and test harness

**Files:**
- Create: `.ruby-version`, `bin/check`, `test/test_helper.rb`, `test/proof.rb`, `test/site/smoke_test.rb`
- Modify: `Gemfile`, `Gemfile.lock`, `.gitignore`, `.github/workflows/deploy.yml`, `_config.yml` (exclude list only)

**Interfaces:**
- Produces: `SITE_DIR` constant and `SiteHelpers#page(path) -> Nokogiri::HTML::Document`, `SiteHelpers#all_html_files -> Array<String>` (built pages outside `/assets/`), `SiteHelpers#css -> String` (built `main.css`). `bin/check [jekyll build args]` builds, runs every `test/**/*_test.rb`, then html-proofer.

- [ ] **Step 1: Pin Ruby and stop ignoring lock/version files**

```bash
echo "4.0.5" > .ruby-version
sed -i '' '/^Gemfile.lock$/d;/^\.ruby-version$/d' .gitignore
grep -n "Gemfile.lock\|ruby-version" .gitignore || echo "ok: no longer ignored"
```

- [ ] **Step 2: Add test gems**

Append to `Gemfile`:

```ruby
group :test do
  gem 'html-proofer', '~> 5.0'
  gem 'minitest', '~> 6.0'
end
```

Run: `bundle install`
Expected: `Bundle complete!`

- [ ] **Step 3: Exclude non-site folders from the build**

In `_config.yml`, add these entries to the existing `exclude:` list:

```yaml
  - .superpowers/
  - .playwright-mcp/
  - docs/
  - test/
  - bin/
```

- [ ] **Step 4: Write the test helper, proofer and smoke test**

`test/test_helper.rb`:

```ruby
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
```

`test/proof.rb`:

```ruby
require 'html-proofer'

HTMLProofer.check_directory(
  File.expand_path('../_site', __dir__),
  checks: %w[Links Images Scripts],
  disable_external: true,
  enforce_https: false,
  allow_missing_href: true,
  ignore_files: [%r{/_site/assets/}]
).run
```

`test/site/smoke_test.rb`:

```ruby
require_relative '../test_helper'

class SmokeTest < Minitest::Test
  include SiteHelpers

  def test_home_page_is_built_with_site_title
    assert_equal 'Philipp Haslbauer', page('/').at_css('title').text.strip
  end
end
```

- [ ] **Step 5: Write `bin/check`**

```bash
#!/usr/bin/env bash
# Build the site, run the Minitest suite, then check internal links and images.
set -euo pipefail
cd "$(dirname "$0")/.."
bundle exec jekyll build --quiet "$@"
bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |f| require File.expand_path(f) }'
bundle exec ruby test/proof.rb
```

Run: `chmod +x bin/check && bin/check`
Expected: build succeeds, `1 runs, 1 assertions, 0 failures`. html-proofer may report failures in the unmodified site; copy its failure list verbatim into `LOG.md` under "Baseline html-proofer failures". These are the baseline failures referred to in Global Constraints.

- [ ] **Step 6: Rewrite the deploy workflow**

Replace `.github/workflows/deploy.yml` with:

```yaml
name: Deploy site

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive
      - name: Setup Ruby (version from .ruby-version)
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Install ImageMagick
        run: sudo apt-get update && sudo apt-get install -y imagemagick
      - name: Build
        run: JEKYLL_ENV=production bundle exec jekyll build
      - name: Test
        run: |
          bundle exec ruby -Itest -e 'Dir["test/**/*_test.rb"].sort.each { |f| require File.expand_path(f) }'
          bundle exec ruby test/proof.rb
      - name: Purge unused CSS
        run: |
          npm install -g purgecss
          purgecss -c purgecss.config.js
      - name: Deploy
        if: github.event_name != 'pull_request'
        uses: JamesIves/github-pages-deploy-action@v4
        with:
          folder: _site
```

The Test step will fail on CI while baseline html-proofer failures exist; that only matters once a PR is opened (Task 13).

- [ ] **Step 7: Save the baseline page list**

```bash
find _site -name '*.html' -not -path '_site/assets/*' | sed 's|^_site||' | sort > "/Volumes/T7 Shield/Temp/website-redesign/baseline-pages.txt"
```

- [ ] **Step 8: Commit**

```bash
git add .ruby-version .gitignore Gemfile Gemfile.lock _config.yml bin/check test .github/workflows/deploy.yml
git commit -m "Pin Ruby, track Gemfile.lock, add site test harness"
```

---

### Task 2: Experiments generator — strict metadata and exclude list

**Files:**
- Modify: `_plugins/experiments_generator.rb`, `_config.yml`
- Test: `test/plugins/experiments_generator_test.rb`

**Interfaces:**
- Produces: config key `experiments_exclude: [<dir name>, ...]`. Invalid `meta.json` raises `Jekyll::Errors::FatalException` whose message contains the experiment directory.

- [ ] **Step 1: Write the failing tests**

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bundle exec ruby -Itest test/plugins/experiments_generator_test.rb`
Expected: `test_invalid_meta_fails_the_build` fails (no exception raised) and `test_excluded_experiment_is_skipped_with_its_files` fails (2 titles).

- [ ] **Step 3: Implement**

In `_plugins/experiments_generator.rb`, replace the loop in `generate` and the `rescue` in `read_meta`:

```ruby
      excluded = Array(site.config['experiments_exclude'])

      Dir.glob(File.join(src_dir, '*')).select { |f| File.directory?(f) }.sort.each do |exp_dir|
        name = File.basename(exp_dir)
        if excluded.include?(name)
          Jekyll.logger.info 'ExperimentsGenerator:', "skipping excluded experiment '#{name}'"
          next
        end

        meta = read_meta(exp_dir)

        add_experiment_doc(site, name, meta)
        add_static_files(site, exp_dir, name)

        Jekyll.logger.info 'ExperimentsGenerator:', "registered experiment '#{name}'"
      end
```

```ruby
    rescue JSON::ParserError => e
      raise Jekyll::Errors::FatalException, "ExperimentsGenerator: invalid meta.json in #{dir}: #{e.message}"
```

Add to `_config.yml` (top level, next to the collections block):

```yaml
experiments_exclude: [mhg-scriptorium] # experiment folders in _experiments_src/public not shown on the site
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bundle exec ruby -Itest test/plugins/experiments_generator_test.rb`
Expected: `3 runs, ... 0 failures, 0 errors`

Run: `bundle exec jekyll build 2>&1 | grep ExperimentsGenerator`
Expected: `skipping excluded experiment 'mhg-scriptorium'` and `registered experiment 'morse-chatbot'`.

- [ ] **Step 5: Commit**

```bash
git add _plugins/experiments_generator.rb _config.yml test/plugins/experiments_generator_test.rb
git commit -m "Fail build on invalid experiment meta.json; support experiments_exclude"
```

---

### Task 3: Remove upstream repository cruft

**Files:**
- Delete: `.all-contributorsrc`, `.devcontainer/`, `.dockerignore`, `.git-blame-ignore-revs`, `.pre-commit-config.yaml`, `.prettierignore`, `.prettierrc`, `CONTRIBUTING.md`, `CUSTOMIZE.md`, `FAQ.md`, `INSTALL.md`, `Dockerfile`, `docker-compose.yml`, `docker-compose-slim.yml`, `bin/cibuild`, `bin/deploy`, `bin/entry_point.sh`, `package.json`, `package-lock.json`, `requirements.txt`, `readme_preview/`, `lighthouse_results/`, `.github/ISSUE_TEMPLATE/`, `.github/release.yml`, `.github/stale.yml`, all workflows except `deploy.yml` and `broken-links-site.yml`, `.github/workflows/schedule-posts.txt`, `.tweet-cache/` (untracked; plain `rm -rf`)
- Modify: `_config.yml` (exclude list), `README.md` (temporary stub; rewritten in Task 13)

- [ ] **Step 1: Delete**

```bash
git rm -rq .all-contributorsrc .devcontainer .dockerignore .git-blame-ignore-revs .pre-commit-config.yaml \
  .prettierignore .prettierrc CONTRIBUTING.md CUSTOMIZE.md FAQ.md INSTALL.md Dockerfile docker-compose.yml \
  docker-compose-slim.yml bin/cibuild bin/deploy bin/entry_point.sh package.json package-lock.json requirements.txt \
  readme_preview lighthouse_results .github/ISSUE_TEMPLATE .github/release.yml .github/stale.yml \
  .github/workflows/axe.yml .github/workflows/broken-links.yml .github/workflows/codeql.yml \
  .github/workflows/deploy-docker-tag.yml .github/workflows/deploy-image.yml .github/workflows/docker-slim.yml \
  .github/workflows/lighthouse-badger.yml .github/workflows/prettier-comment-on-pr.yml \
  .github/workflows/prettier-html.yml .github/workflows/prettier.yml .github/workflows/update-tocs.yml \
  .github/workflows/schedule-posts.txt
rm -rf .tweet-cache
ls .github/workflows
```

Expected: `broken-links-site.yml  deploy.yml`

- [ ] **Step 2: Replace the README with a stub**

`README.md`:

```markdown
# philipphaslbauer.com

Personal site of Philipp Haslbauer. Jekyll, originally forked from [al-folio](https://github.com/alshedivat/al-folio) (MIT, see LICENSE).

Run `bin/check` to build and test. Full documentation follows.
```

- [ ] **Step 3: Trim the exclude list**

In `_config.yml`, remove these now-deleted entries from `exclude:`: `CONTRIBUTING.md`, `CUSTOMIZE.md`, `Dockerfile`, `docker-compose.yml`, `docker-compose-slim.yml`, `FAQ.md`, `INSTALL.md`, `lighthouse_results/`, `package.json`, `package-lock.json`, `readme_preview/`.

- [ ] **Step 4: Build and test**

Run: `bin/check`
Expected: build succeeds; smoke and generator tests pass; html-proofer shows only baseline failures.

- [ ] **Step 5: Commit**

```bash
git add -A .github README.md _config.yml
git commit -m "Remove upstream al-folio docs, tooling and workflows"
```

---

### Task 4: Minimal page shell and runtime JS (fixes `determineComputedTheme` error)

**Files:**
- Modify: `_layouts/default.liquid`, `_includes/head.liquid`, `_includes/scripts.liquid`, `assets/js/common.js`
- Delete: every file in `assets/js/` except `bootstrap.bundle.min.js`, `bootstrap.bundle.min.js.map`, `common.js`, `bibsearch.js`, `highlight-search-term.js`; `_scripts/`; CSS files `assets/css/{bootstrap-toc.min.css,jekyll-pygments-themes-github.css,jekyll-pygments-themes-native.css,jupyter.css,jupyter-grade3.css,jupyter-monokai.css,mdb.min.css,mdb.min.css.map,academicons.min.css,scholar-icons.css}`
- Test: `test/site/scripts_test.rb`

**Interfaces:**
- Produces: `default.liquid` renders `header.liquid`, `<main id="main" class="container site-main">`, `footer.liquid`, `scripts.liquid`. Only local scripts: `bootstrap.bundle.min.js`, `common.js`, and `bibsearch.js` (publications only).

- [ ] **Step 1: Write the failing tests**

`test/site/scripts_test.rb`:

```ruby
require_relative '../test_helper'

class ScriptsTest < Minitest::Test
  include SiteHelpers

  ALLOWED_LOCAL = %w[bootstrap.bundle.min.js common.js bibsearch.js].freeze
  ALLOWED_EXTERNAL = [
    %r{\Ahttps://cdn\.jsdelivr\.net/npm/jquery@3\.6\.0/dist/jquery\.min\.js\z},
    %r{\Ahttps://unpkg\.com/es-module-shims@}
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `ScriptsTest` fails (e.g. `no_defer.js`, MDB, MathJax, `determineComputedTheme`).

- [ ] **Step 3: Replace the shell templates**

`_layouts/default.liquid`:

```liquid
<!doctype html>
<html lang="{{ site.lang }}">
  <head>
    {% include head.liquid %}
  </head>
  <body>
    <a class="skip-link" href="#main">Skip to content</a>
    {% include header.liquid %}
    <main id="main" class="container site-main">
      {{ content }}
    </main>
    {% include footer.liquid %}
    {% include scripts.liquid %}
  </body>
</html>
```

`_includes/head.liquid`:

```liquid
{% include metadata.liquid %}
<link rel="stylesheet" href="{{ '/assets/css/bootstrap.min.css' | relative_url | bust_file_cache }}">
{% if site.icon != blank %}
  <link rel="icon" href="{{ site.icon | prepend: '/assets/img/' | relative_url | bust_file_cache }}">
{% endif %}
<link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url | bust_css_cache }}">
<link rel="canonical" href="{{ page.url | replace: 'index.html', '' | absolute_url }}">
```

`_includes/scripts.liquid`:

```liquid
<script
  src="https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js"
  integrity="sha256-/xUj+3OJU5yExlq6GSYGSHk7tPXikynS7ogEvDej/m4="
  crossorigin="anonymous"
></script>
<script src="{{ '/assets/js/bootstrap.bundle.min.js' | relative_url }}"></script>
<script defer src="{{ '/assets/js/common.js' | relative_url | bust_file_cache }}"></script>
```

`assets/js/common.js`:

```js
// Publication entries: the abstract, award and bibtex panels toggle and are mutually exclusive.
$(document).ready(function () {
  const panels = ["abstract", "award", "bibtex"];
  $("a.abstract, a.award, a.bibtex").click(function () {
    const clicked = panels.find((kind) => $(this).hasClass(kind));
    const entry = $(this).parent().parent();
    panels.forEach((kind) => {
      const panel = entry.find(`.${kind}.hidden`);
      if (kind === clicked) panel.toggleClass("open");
      else panel.removeClass("open");
    });
  });
});
```

- [ ] **Step 4: Delete unused JS and CSS**

```bash
cd assets/js && git rm -rq $(ls | grep -vxE 'bootstrap\.bundle\.min\.js(\.map)?|common\.js|bibsearch\.js|highlight-search-term\.js') && cd ../..
git rm -rq _scripts assets/css/bootstrap-toc.min.css assets/css/jekyll-pygments-themes-github.css \
  assets/css/jekyll-pygments-themes-native.css assets/css/jupyter.css assets/css/jupyter-grade3.css \
  assets/css/jupyter-monokai.css assets/css/mdb.min.css assets/css/mdb.min.css.map \
  assets/css/academicons.min.css assets/css/scholar-icons.css
sed -i '' 's/^include: \["_pages", "_scripts"\]/include: ["_pages"]/' _config.yml
ls assets/js assets/css
```

Expected: `assets/js`: `bibsearch.js bootstrap.bundle.min.js bootstrap.bundle.min.js.map common.js highlight-search-term.js`; `assets/css`: `bootstrap.min.css bootstrap.min.css.map main.scss`.

- [ ] **Step 5: Run to verify pass**

Run: `bin/check`
Expected: all tests pass; html-proofer shows only baseline failures.

- [ ] **Step 6: Console check in a real browser**

With `bundle exec jekyll serve --port 4001` running in the background, open `/`, `/works/`, `/publications/`, `/experiments/`, `/blog/` with the Playwright MCP and read console messages.
Expected: no `ReferenceError`. Record the result in `LOG.md`.

- [ ] **Step 7: Commit**

```bash
git add -A _layouts/default.liquid _includes/head.liquid _includes/scripts.liquid assets/js assets/css _scripts _config.yml test/site/scripts_test.rb
git commit -m "Reduce page shell to Bootstrap, jQuery and one script; drop theme toggle remnants"
```

---

### Task 5: Prune plugins, gems, configuration, example data and demo assets

**Files:**
- Modify: `Gemfile`, `Gemfile.lock`, `_config.yml` (full rewrite), `_layouts/bib.liquid` (remove badges block only)
- Delete: `_plugins/{google-scholar-citations.rb,inspirehep-citations.rb,download-3rd-party.rb,details.rb}`, `_pages/{teaching.md,dropdown.md}`, `_data/{venues.yml,coauthors.yml,repositories.yml}`, `assets/{video,audio,plotly,jupyter,bibliography,html,json}/`, `assets/pdf/example_pdf.pdf`, `assets/projects/` (duplicate of `assets/img/projects/`), `assets/img/template_error.png`
- Test: `test/site/pages_test.rb`

**Interfaces:**
- Consumes: `experiments_exclude` (Task 2).
- Produces: config keys used later: `scholar.*`, `filtered_bibtex_keywords` (includes `featured`, `featured_order`, `featured_title`, `featured_description`), `max_author_limit`, `more_authors_animation_delay`, `enable_publication_thumbnails`, `bib_search`, `blog_description`, `external_sources`, `imagemagick`, `collections.projects.permalink: /works/:name/`.

- [ ] **Step 1: Write the failing test**

`test/site/pages_test.rb`:

```ruby
require_relative '../test_helper'

class PagesTest < Minitest::Test
  include SiteHelpers

  EXPECTED = %w[
    /404.html /index.html /works/index.html /works/deus-in-machina/index.html
    /publications/index.html /experiments/index.html /experiments/one/index.html
    /experiments/two/index.html /experiments/morse-chatbot/index.html /blog/index.html
    /blog/2023/controlling-diffusion/index.html /blog/2024/easy-3dgs/index.html /cv/index.html
  ].freeze
  EXTERNAL_POST = %r{\A/blog/\d{4}/[^/]+/index\.html\z}

  def built_pages
    all_html_files.map { |f| f.delete_prefix(SITE_DIR) }
  end

  def test_all_expected_pages_exist
    assert_empty EXPECTED - built_pages
  end

  def test_no_unexpected_pages
    extra = (built_pages - EXPECTED).reject { |p| EXTERNAL_POST.match?(p) }
    assert_empty extra
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `PagesTest` fails: missing `/works/deus-in-machina/`; extra `/teaching/`, `/_pages/dropdown/`, `/blog/category/...`, `/blog/2023/index.html`, `/projects/deus-in-machina/`.

- [ ] **Step 3: Remove the badges block from `bib.liquid`**

The citation-count plugins register Liquid tags that `bib.liquid` uses, so the block must go first:

```bash
python3 - <<'EOF'
p = '_layouts/bib.liquid'
s = open(p).read()
start = s.index('    {% if site.enable_publication_badges %}')
end = s.index('    {% if entry.award %}\n      <!-- Hidden Award block -->')
open(p, 'w').write(s[:start] + s[end:])
EOF
grep -c "google_scholar_citations\|inspirehep_citations\|altmetric" _layouts/bib.liquid
```

Expected: `0`

- [ ] **Step 4: Prune the Gemfile**

Replace `Gemfile` with:

```ruby
source 'https://rubygems.org'

gem 'jekyll'

group :jekyll_plugins do
  gem 'jekyll-email-protect'
  gem 'jekyll-feed'
  gem 'jekyll-imagemagick'
  gem 'jekyll-link-attributes'
  gem 'jekyll-minifier'
  gem 'jekyll-paginate-v2'
  gem 'jekyll-regex-replace'
  gem 'jekyll-scholar'
  gem 'jekyll-sitemap'
  gem 'jekyll-terser', :git => "https://github.com/RobertoJBeltran/jekyll-terser.git"
  gem 'jekyll-toc'
end

group :other_plugins do
  gem 'feedjira'  # used by _plugins/external-posts.rb
  gem 'httparty'  # used by _plugins/external-posts.rb
  gem 'observer'  # used by jekyll-scholar
  gem 'ostruct'   # no longer a default gem since Ruby 3.5
end

group :test do
  gem 'html-proofer', '~> 5.0'
  gem 'minitest', '~> 6.0'
end
```

Run: `bundle install`
Expected: `Bundle complete!`

- [ ] **Step 5: Rewrite `_config.yml`**

Replace the whole file with:

```yaml
# Site
title: Philipp Haslbauer
first_name: Philipp
last_name: Haslbauer
description: >
  Software developer, researcher, and artist based in Lucerne, Switzerland.
keywords: portfolio, interactive media, artificial intelligence, gaussian splatting
lang: en
max_width: 1100px # read by the old main.scss; removed with it in Task 6
icon: favicon.ico # in /assets/img/
url: https://philipphaslbauer.com
baseurl:

google_site_verification: JXSZt1SMxUkVgA2tWsJ71GeJ4utjZN3duCWYhUwG_dk
enable_google_verification: true

# Blog
blog_description: Thoughts, art, and AI.
permalink: /blog/:year/:title/
pagination:
  enabled: true
external_sources:
  - name: Substack
    rss_url: https://philipphaslbauer.substack.com/feed

# Collections
collections:
  projects:
    output: true
    permalink: /works/:name/
  experiments:
    output: true
experiments_exclude: [mhg-scriptorium] # folders in _experiments_src/public not shown on the site

# Publications (jekyll-scholar)
scholar:
  last_name: [Haslbauer, H.]
  first_name: [Philipp, P.]
  style: apa
  locale: en
  source: /_bibliography/
  bibliography: papers.bib
  bibliography_template: bib
  bibtex_filters: [latex, smallcaps, superscript]
  replace_strings: true
  join_strings: true
  details_dir: bibliography
  details_link: Details
  query: "@*"
  group_by: year
  group_order: descending
filtered_bibtex_keywords:
  [abbr, abstract, additional_info, annotation, arxiv, award, award_name, bibtex_show, blog, code,
   featured, featured_description, featured_order, featured_title, html, pdf, poster, preview,
   selected, slides, supp, video, website]
max_author_limit: 3
more_authors_animation_delay: 10
enable_publication_thumbnails: true
bib_search: true

# Build
markdown: kramdown
highlighter: rouge
kramdown:
  input: GFM
  syntax_highlighter_opts:
    css_class: "highlight"
    span:
      line_numbers: false
    block:
      line_numbers: false
include: ["_pages"]
exclude:
  - bin/
  - docs/
  - test/
  - Gemfile
  - Gemfile.lock
  - LICENSE
  - purgecss.config.js
  - README.md
  - vendor
  - .superpowers/
  - .playwright-mcp/
keep_files:
  - CNAME
  - .nojekyll

plugins:
  - jekyll-email-protect
  - jekyll-feed
  - jekyll-imagemagick
  - jekyll-link-attributes
  - jekyll-paginate-v2
  - jekyll-regex-replace
  - jekyll/scholar
  - jekyll-sitemap
  - jekyll-toc

defaults:
  - scope:
      path: "assets"
    values:
      sitemap: false

sass:
  style: compressed

external_links:
  enabled: true
  rel: external nofollow noopener
  target: _blank
  exclude:

jekyll-minifier:
  compress_javascript: false
  exclude:
    - robots.txt
    - assets/demos/**/*.js
    - assets/demos

terser:
  compress:
    drop_console: true

imagemagick:
  enabled: true
  widths: [480, 800, 1400]
  input_directories:
    - assets/img/
  input_formats: [".jpg", ".jpeg", ".png", ".tiff", ".gif"]
  output_formats:
    webp: "-quality 85"
lazy_loading_images: true
```

- [ ] **Step 6: Delete plugins, pages, example data and demo assets**

```bash
grep -rl "{% *details" _posts _projects _pages _experiments || echo "details tag unused"
git rm -q _plugins/google-scholar-citations.rb _plugins/inspirehep-citations.rb _plugins/download-3rd-party.rb \
  _plugins/details.rb _pages/teaching.md _pages/dropdown.md _data/venues.yml _data/coauthors.yml \
  _data/repositories.yml assets/pdf/example_pdf.pdf assets/img/template_error.png
git rm -rq assets/video assets/audio assets/plotly assets/jupyter assets/bibliography assets/html assets/json assets/projects
git grep -n "assets/projects/" -- ':!docs' || echo "no references to assets/projects"
```

Expected: `details tag unused`, `no references to assets/projects`.

- [ ] **Step 7: Run to verify pass and inspect warnings**

Run: `bundle exec jekyll build 2>&1 | grep -iE "warn|error|registered experiment" | grep -v DEPRECATION`
Expected: `registered experiment 'morse-chatbot'`, `skipping excluded experiment 'mhg-scriptorium'`, no `Empty slug` warnings (they came from jekyll-archives), no `Unknown tag`.

Run: `bin/check`
Expected: all tests pass, including `PagesTest`. html-proofer additionally reports broken `/blog/tag/…`, `/blog/category/…` and `/blog/<year>/` links from the old blog templates; list them in `LOG.md` (Task 11 removes them).

- [ ] **Step 8: Check config keys still read by templates**

```bash
git grep -hoE "site\.[a-z_]+" -- _layouts _includes _pages _plugins | sort -u
```

Every key listed must be either defined in the new `_config.yml`, a Jekyll built-in (`site.pages`, `site.posts`, `site.data`, `site.time`, `site.collections`, ...), or inside a template that a later task rewrites or deletes (`about_cv`, `cv`, `post`, `page`, `header`, `footer`, `social`, `projects`, `news`, `latest_posts`, `giscus`, `disqus`, ...). Note any other key in `LOG.md` and add it to `_config.yml`.

- [ ] **Step 9: Commit**

```bash
git add -A Gemfile Gemfile.lock _config.yml _layouts/bib.liquid _plugins _pages _data assets test/site/pages_test.rb
git commit -m "Drop unused plugins, gems, config, placeholder pages and demo assets"
```

---

### Task 6: Design foundation — fonts, tokens, Sass partials, header and footer

**Files:**
- Create: `assets/fonts/{pixelify-sans,jetbrains-mono,source-serif-4}-*.woff2` (12 files), `_sass/_breakpoints.scss`, `_sass/_tokens.scss`, `_sass/_fonts.scss`, `_sass/_base.scss` (new content), `_sass/_layout.scss` (new content), `_sass/_nav.scss`, `_sass/_footer.scss`, `_includes/links.liquid`
- Modify: `assets/css/main.scss`, `_includes/header.liquid`, `_includes/footer.liquid`, `_pages/*.md` (`nav_order` only)
- Delete: `_sass/{_variables,_themes,_distill,_tabs,_typograms}.scss`, `_sass/font-awesome/`, `_sass/tabler-icons/`, old `_sass/_base.scss` and `_sass/_layout.scss` content (overwritten), `_sass/_cv.scss` (recreated in Task 12)
- Test: `test/site/style_test.rb`

**Interfaces:**
- Produces CSS classes used by every later task: `.page-header`, `.page-title`, `.lede`, `.section-label`, `.meta`, `.badge-kind`, `.chip`, `.chips`, `.text-links`, `.skip-link`; CSS variables listed in Global Constraints plus `--font-display`, `--font-mono`, `--font-serif`, `--step--2 … --step-5`, `--space-1 … --space-16`, `--content-max`, `--measure`, `--gutter`. Sass module `breakpoints` with `$sm: 576px; $md: 768px; $lg: 992px`.
- Produces `_includes/links.liquid`: renders `<ul class="text-links">` with email, instagram, linkedin, scholar, cv.
- Icons from Font Awesome, Academicons and Tabler stop rendering after this task; the templates still using them are rewritten in Tasks 8–12.

- [ ] **Step 1: Write the failing tests**

`test/site/style_test.rb`:

```ruby
require_relative '../test_helper'

class StyleTest < Minitest::Test
  include SiteHelpers

  TOKENS = {
    '--bg' => '#07110b', '--text' => '#cfe6d2', '--head' => '#c6f7bd',
    '--accent' => '#ff7ac2', '--muted' => '#86a08c', '--rule' => '#26402e'
  }.freeze
  FONT_FILES = %w[pixelify-sans-latin-500-normal jetbrains-mono-latin-400-normal source-serif-4-latin-400-normal].freeze

  def test_palette_tokens_are_defined
    TOKENS.each { |name, value| assert_match(/#{Regexp.escape(name)}:\s*#{value}/i, css, name) }
  end

  def test_fonts_are_self_hosted
    all_html_files.each { |f| refute_match(/fonts\.googleapis\.com/, File.read(f), f) }
    FONT_FILES.each do |name|
      assert File.exist?(File.join(SITE_DIR, "assets/fonts/#{name}.woff2")), name
      assert_includes css, "#{name}.woff2"
    end
  end

  def test_no_light_theme_or_icon_font_css
    refute_match(/prefers-color-scheme:\s*light|data-theme/, css)
    refute_match(/font-family:\s*["']?(Font Awesome|tabler-icons|Academicons)/i, css)
  end

  def test_footer_is_static_and_has_links
    footer = page('/').at_css('footer.site-footer')
    assert footer
    refute_match(/fixed/, footer['class'])
    assert_equal %w[email instagram linkedin scholar cv], footer.css('.text-links a').map { |a| a.text.strip }
  end

  def test_nav_marks_current_section
    link = page('/publications/').at_css('#site-nav a.active')
    assert_equal 'publications', link.text.strip
    assert_equal 'page', link['aria-current']
  end

  def test_nav_order
    labels = page('/blog/').css('#site-nav .nav-link').map { |a| a.text.strip }
    assert_equal %w[about works publications experiments blog], labels
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `StyleTest` failures (tokens missing, Google Fonts link in old CSS imports, no `.site-footer`).

- [ ] **Step 3: Download fonts**

```bash
mkdir -p assets/fonts
for spec in pixelify-sans:500-normal jetbrains-mono:400-normal jetbrains-mono:500-normal \
            source-serif-4:400-normal source-serif-4:400-italic source-serif-4:600-normal; do
  family=${spec%%:*}; variant=${spec#*:}
  for subset in latin latin-ext; do
    curl -fsSL -o "assets/fonts/${family}-${subset}-${variant}.woff2" \
      "https://cdn.jsdelivr.net/fontsource/fonts/${family}@latest/${subset}-${variant}.woff2"
  done
done
ls assets/fonts/*-latin*-*.woff2 | wc -l
```

Expected: `12`. All three families are SIL Open Font License 1.1; add one line per family to `LOG.md` with the source URL.

- [ ] **Step 4: Write the Sass partials**

`_sass/_breakpoints.scss`:

```scss
$sm: 576px;
$md: 768px;
$lg: 992px;
```

`_sass/_tokens.scss`:

```scss
:root {
  --bg: #07110b;
  --text: #cfe6d2;
  --head: #c6f7bd;
  --accent: #ff7ac2;
  --muted: #86a08c;
  --rule: #26402e;
  --glow: 0 0 8px rgba(198, 247, 189, 0.35);

  --font-display: "Pixelify Sans", ui-monospace, monospace;
  --font-mono: "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, monospace;
  --font-serif: "Source Serif 4", Georgia, "Times New Roman", serif;

  // modular scale, ratio 1.25
  --step--2: 0.64rem;
  --step--1: 0.8rem;
  --step-0: 1rem;
  --step-1: 1.25rem;
  --step-2: 1.563rem;
  --step-3: 1.953rem;
  --step-4: 2.441rem;
  --step-5: 3.052rem;

  --space-1: 0.25rem;
  --space-2: 0.5rem;
  --space-3: 0.75rem;
  --space-4: 1rem;
  --space-6: 1.5rem;
  --space-8: 2rem;
  --space-12: 3rem;
  --space-16: 4rem;

  --content-max: 1100px;
  --measure: 68ch;
  --gutter: 20px;
}

@media (min-width: 576px) {
  :root {
    --gutter: 32px;
  }
}
```

`_sass/_fonts.scss`:

```scss
$latin: "U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD";
$latin-ext: "U+0100-02BA, U+02BD-02C5, U+02C7-02CC, U+02CE-02D7, U+02DD-02FF, U+0304, U+0308, U+0329, U+1D00-1DBF, U+1E00-1E9F, U+1EF2-1EFF, U+2020, U+20A0-20AB, U+20AD-20C0, U+2113, U+2C60-2C7F, U+A720-A7FF";

@mixin face($family, $file, $weight, $style: normal) {
  @each $subset, $range in (latin: $latin, latin-ext: $latin-ext) {
    @font-face {
      font-family: $family;
      font-style: $style;
      font-weight: $weight;
      font-display: swap;
      src: url("../fonts/#{$file}-#{$subset}-#{$weight}-#{$style}.woff2") format("woff2");
      unicode-range: #{$range};
    }
  }
}

@include face("Pixelify Sans", "pixelify-sans", 500);
@include face("JetBrains Mono", "jetbrains-mono", 400);
@include face("JetBrains Mono", "jetbrains-mono", 500);
@include face("Source Serif 4", "source-serif-4", 400);
@include face("Source Serif 4", "source-serif-4", 400, italic);
@include face("Source Serif 4", "source-serif-4", 600);
```

`_sass/_base.scss` (overwrite):

```scss
*,
*::before,
*::after {
  box-sizing: border-box;
}

html,
body {
  background: var(--bg);
}

body {
  margin: 0;
  color: var(--text);
  font-family: var(--font-serif);
  font-size: 1.0625rem;
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}

h1,
h2,
h3,
h4 {
  color: var(--head);
  font-weight: 500;
  line-height: 1.2;
  margin: 0 0 var(--space-3);
  overflow-wrap: anywhere;
}

h1 {
  font-family: var(--font-display);
  font-size: var(--step-4);
  text-shadow: var(--glow);
}

h2,
h3,
h4 {
  font-family: var(--font-mono);
}

h2 {
  font-size: var(--step-2);
}

h3 {
  font-size: var(--step-1);
}

h4 {
  font-size: var(--step-0);
}

p {
  margin: 0 0 var(--space-4);
}

a {
  color: var(--accent);
  text-decoration: underline;
  text-decoration-color: var(--rule);
  text-underline-offset: 0.2em;

  &:hover,
  &:focus-visible {
    color: var(--accent);
    text-decoration-color: currentColor;
  }
}

:focus-visible {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}

img {
  max-width: 100%;
  height: auto;
}

figure {
  margin: 0;
}

hr {
  border: 0;
  border-top: 1px solid var(--rule);
}

::selection {
  background: var(--accent);
  color: var(--bg);
}

.skip-link {
  position: absolute;
  left: -9999px;

  &:focus {
    left: var(--gutter);
    top: var(--space-2);
    z-index: 2000;
    background: var(--bg);
    padding: var(--space-2) var(--space-3);
  }
}

.section-label {
  font-family: var(--font-mono);
  font-size: var(--step--1);
  font-weight: 400;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: var(--accent);
  text-shadow: none;
  margin: var(--space-12) 0 var(--space-4);
}

.meta {
  font-family: var(--font-mono);
  font-size: var(--step--1);
  color: var(--muted);
}

.badge-kind {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: var(--step--2);
  letter-spacing: 0.1em;
  text-transform: uppercase;
  background: var(--accent);
  color: var(--bg);
  padding: 1px 6px;
}

.chips {
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2);
  margin-top: var(--space-2);
}

.chip {
  display: inline-block;
  font-family: var(--font-mono);
  font-size: var(--step--2);
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--text);
  background: transparent;
  border: 1px solid var(--rule);
  border-radius: 0;
  padding: 2px 8px;
  text-decoration: none;
  cursor: pointer;

  &:hover,
  &:focus-visible {
    color: var(--accent);
    border-color: var(--accent);
  }
}

.text-links {
  list-style: none;
  display: flex;
  flex-wrap: wrap;
  gap: var(--space-2) var(--space-4);
  padding: 0;
  margin: var(--space-4) 0 0;
  font-family: var(--font-mono);
  font-size: var(--step--1);

  a {
    color: var(--head);
  }
}
```

`_sass/_layout.scss` (overwrite):

```scss
.container {
  max-width: var(--content-max);
  padding-left: var(--gutter);
  padding-right: var(--gutter);
}

.site-main {
  padding-top: var(--space-8);
  padding-bottom: var(--space-16);
  min-height: 70vh;
}

.page-header {
  margin-bottom: var(--space-8);
}

.page-title {
  font-size: var(--step-4);
}

.lede {
  max-width: var(--measure);
  font-size: var(--step-1);
  line-height: 1.5;
}
```

`_sass/_nav.scss`:

```scss
@use "breakpoints" as bp;

.site-header .navbar {
  padding-top: var(--space-6);
  padding-bottom: var(--space-6);
}

.site-header__name,
.site-header .nav-link {
  font-family: var(--font-display);
  font-size: var(--step-1);
  color: var(--head);
  text-decoration: none;
}

.site-header__name:hover,
.site-header .nav-link:hover,
.site-header .nav-link.active {
  color: var(--accent);
}

.site-header .navbar-nav .nav-link {
  padding: var(--space-1) var(--space-2);
}

.site-header .navbar-toggler {
  font-family: var(--font-mono);
  font-size: var(--step--1);
  color: var(--head);
  border: 1px solid var(--rule);
  border-radius: 0;
  padding: var(--space-1) var(--space-3);
}

@media (max-width: bp.$md - 0.02px) {
  .site-header .navbar-nav {
    align-items: flex-end;
    padding-top: var(--space-4);
  }
}
```

`_sass/_footer.scss`:

```scss
.site-footer {
  border-top: 1px solid var(--rule);
  padding: var(--space-8) 0;
  color: var(--muted);
  font-family: var(--font-mono);
  font-size: var(--step--1);

  p {
    margin: 0;
  }

  .text-links {
    margin: 0;
  }
}

.site-footer__inner {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  align-items: center;
  gap: var(--space-4);
}
```

`assets/css/main.scss` (overwrite):

```scss
---
---
@use "tokens";
@use "fonts";
@use "base";
@use "layout";
@use "nav";
@use "footer";
```

Later tasks append `@use` lines for `card`, `prose`, `publications`, `row`, `code`, `cv`, `print`.

- [ ] **Step 5: Delete old Sass and the old width setting**

```bash
git rm -rq _sass/_variables.scss _sass/_themes.scss _sass/_distill.scss _sass/_tabs.scss _sass/_typograms.scss \
  _sass/_cv.scss _sass/font-awesome _sass/tabler-icons
ls _sass
```

Expected: `_base.scss _breakpoints.scss _fonts.scss _footer.scss _layout.scss _nav.scss _tokens.scss`

Delete the `max_width:` line from `_config.yml`, and add the display-font preload to `_includes/head.liquid` directly after the metadata include:

```liquid
<link rel="preload" href="{{ '/assets/fonts/pixelify-sans-latin-500-normal.woff2' | relative_url }}" as="font" type="font/woff2" crossorigin>
```

- [ ] **Step 6: Header, footer and text links**

`_includes/links.liquid`:

```liquid
{% assign s = site.data.socials %}
<ul class="text-links">
  {% if s.email %}<li><a href="mailto:{{ s.email | encode_email }}">email</a></li>{% endif %}
  {% if s.instagram_id %}<li><a href="https://instagram.com/{{ s.instagram_id }}" rel="me">instagram</a></li>{% endif %}
  {% if s.linkedin_username %}<li><a href="https://www.linkedin.com/in/{{ s.linkedin_username }}" rel="me">linkedin</a></li>{% endif %}
  {% if s.scholar_userid %}<li><a href="https://scholar.google.com/citations?user={{ s.scholar_userid }}">scholar</a></li>{% endif %}
  <li><a href="{{ '/cv/' | relative_url }}">cv</a></li>
</ul>
```

`_includes/header.liquid`:

```liquid
<header class="site-header">
  <nav class="navbar navbar-expand-md container" aria-label="Main">
    {% if page.permalink != '/' %}
      <a class="site-header__name" href="{{ '/' | relative_url }}">{{ site.first_name }} {{ site.last_name }}</a>
    {% endif %}
    <button
      class="navbar-toggler ml-auto"
      type="button"
      data-toggle="collapse"
      data-target="#site-nav"
      aria-controls="site-nav"
      aria-expanded="false"
      aria-label="Toggle navigation"
    >
      menu
    </button>
    <div class="collapse navbar-collapse" id="site-nav">
      <ul class="navbar-nav ml-auto">
        {% assign is_home = false %}
        {% if page.permalink == '/' %}{% assign is_home = true %}{% endif %}
        <li class="nav-item">
          <a class="nav-link{% if is_home %} active{% endif %}" href="{{ '/' | relative_url }}"{% if is_home %} aria-current="page"{% endif %}>about</a>
        </li>
        {% assign nav_pages = site.pages | where: 'nav', true | sort: 'nav_order' %}
        {% for p in nav_pages %}
          {% if p.autogen %}{% continue %}{% endif %}
          {% assign active = false %}
          {% if page.url contains p.url %}{% assign active = true %}{% endif %}
          <li class="nav-item">
            <a class="nav-link{% if active %} active{% endif %}" href="{{ p.url | relative_url }}"{% if active %} aria-current="page"{% endif %}>{{ p.title }}</a>
          </li>
        {% endfor %}
      </ul>
    </div>
  </nav>
</header>
```

`_includes/footer.liquid`:

```liquid
<footer class="site-footer" role="contentinfo">
  <div class="container site-footer__inner">
    <p>&copy; {{ site.time | date: '%Y' }} {{ site.first_name }} {{ site.last_name }}</p>
    {% include links.liquid %}
  </div>
</footer>
```

Set `nav_order` in front matter: `projects.md` 1, `publications.md` 2, `experiments.md` 3, `blog.md` 4. The `autogen` guard skips extra pages that jekyll-paginate-v2 generates from `blog.md`.

- [ ] **Step 7: Run to verify pass**

Run: `bin/check`
Expected: all tests pass.

- [ ] **Step 8: Commit**

```bash
git add -A _config.yml _includes/head.liquid assets/fonts assets/css/main.scss _sass _includes/header.liquid _includes/footer.liquid _includes/links.liquid _pages test/site/style_test.rb
git commit -m "Add design tokens, self-hosted fonts, new header and footer"
```

---

### Task 7: Featured items generator

**Files:**
- Create: `_plugins/featured.rb`
- Test: `test/plugins/featured_test.rb`

**Interfaces:**
- Consumes: front matter `featured`, `featured_order`, `featured_meta`, `year`, `img`, `description`, `redirect` on `projects` and `experiments` docs; BibTeX fields `featured`, `featured_order`, `featured_title`, `featured_description`, `abbr`, `year`, `preview`, `html`, `doi`, `pdf`.
- Produces: `site.data['featured']`: Array of Hashes with string keys `kind` (`"work"|"experiment"|"paper"`), `title`, `url`, `img` (String or nil), `meta`, `description` (String or nil), `order` (Integer, 999 when unset), `external` (true for papers, false otherwise). Sorted by `[order, title]`.

- [ ] **Step 1: Write the failing tests**

```ruby
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
                            'featured_meta' => '2024–2026 · Lucerne', 'img' => '/assets/img/d.jpg')
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
```

- [ ] **Step 2: Run to verify failure**

Run: `bundle exec ruby -Itest test/plugins/featured_test.rb`
Expected: `LoadError` for `_plugins/featured`.

- [ ] **Step 3: Implement `_plugins/featured.rb`**

```ruby
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
        'meta' => (doc.data['featured_meta'] || doc.data['year']).to_s,
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
```

- [ ] **Step 4: Run to verify pass**

Run: `bundle exec ruby -Itest test/plugins/featured_test.rb`
Expected: `5 runs, ... 0 failures, 0 errors`

Run: `bin/check`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add _plugins/featured.rb test/plugins/featured_test.rb
git commit -m "Add generator collecting featured works, experiments and papers"
```

---

### Task 8: Card component and home page — then REVIEW CHECKPOINT 1

**Files:**
- Create: `_includes/card.liquid`, `_layouts/home.liquid`, `_sass/_card.scss`, `_sass/_home.scss`
- Modify: `_pages/about.md` (rewrite), `assets/css/main.scss`, `_projects/deus-in-machina.md`, `_experiments/two.md`, `_bibliography/papers.bib` (VR Planica entry)
- Delete: `_layouts/about_cv.liquid`, `_includes/social.liquid`
- Test: `test/site/home_test.rb`, `test/includes/card_test.rb`

**Interfaces:**
- Consumes: `site.data['featured']` (Task 7), `links.liquid`, `.section-label`, `.badge-kind` (Task 6).
- Produces: `{% include card.liquid url= img= kind= title= meta= description= external= %}` renders `article.card-item` > `a.card-item__link` (> `figure` or `div.card-item__img--empty`, `span.badge-kind`, `h3.card-item__title`), `p.card-item__meta`, `p.card-item__desc`. Wrapped by callers in `div.card-grid`. Images under `/assets/img/` get the responsive srcset; other paths are passed through with `avoid_scaling`.

- [ ] **Step 1: Write the failing tests**

`test/site/home_test.rb`:

```ruby
require_relative '../test_helper'

class HomeTest < Minitest::Test
  include SiteHelpers

  def home
    @home ||= page('/')
  end

  def test_hero_has_name_bio_and_links
    assert_equal 'Philipp Haslbauer', home.at_css('.hero h1.display-name').text.strip
    assert_includes home.at_css('.hero__bio').text, 'Lucerne'
    assert_equal %w[email instagram linkedin scholar cv], home.css('.hero .text-links a').map { |a| a.text.strip }
  end

  def test_email_link_is_obfuscated_mailto
    href = home.css('.hero .text-links a').find { |a| a.text.strip == 'email' }['href']
    assert href.start_with?('mailto:')
    refute_includes href, '@'
    refute_includes File.read(File.join(SITE_DIR, 'index.html')), 'i@philipphaslbauer.com'
  end

  def test_featured_cards_in_order
    cards = home.css('.featured .card-item')
    assert_equal %w[work paper experiment], cards.map { |c| c.at_css('.badge-kind').text.strip }
    assert_equal ['Deus in Machina', 'VR Planica', 'Voice Puppetry'], cards.map { |c| c.at_css('.card-item__title').text.strip }
    assert_equal '/works/deus-in-machina/', cards[0].at_css('a')['href']
    assert_equal '_blank', cards[1].at_css('a')['target']
  end

  def test_cv_is_not_on_home
    assert_nil home.at_css('.cv')
  end
end
```

`test/includes/card_test.rb` renders the include directly, without a full site build:

```ruby
require 'minitest/autorun'
require 'jekyll'
require 'tmpdir'
require 'nokogiri'

class CardIncludeTest < Minitest::Test
  ROOT = File.expand_path('../..', __dir__)

  def render(markup)
    Dir.mktmpdir do |dir|
      File.symlink(File.join(ROOT, '_includes'), File.join(dir, '_includes'))
      config = Jekyll.configuration('source' => dir, 'destination' => File.join(dir, '_site'), 'quiet' => true)
      site = Jekyll::Site.new(config)
      html = Liquid::Template.parse(markup).render!(site.site_payload, registers: { site: site, page: {} })
      Nokogiri::HTML.fragment(html)
    end
  end

  def test_card_without_image_renders_placeholder
    card = render('{% include card.liquid title="No Image" url="/x/" %}')
    assert card.at_css('.card-item__img--empty')
    assert_nil card.at_css('img')
    assert_equal '/x/', card.at_css('a')['href']
  end

  def test_external_card_opens_in_new_tab
    card = render('{% include card.liquid title="P" url="https://example.org/p" external=true %}')
    assert_equal '_blank', card.at_css('a')['target']
    assert_equal 'https://example.org/p', card.at_css('a')['href']
  end

  def test_empty_meta_is_omitted
    assert_nil render('{% include card.liquid title="T" url="/t/" meta="" %}').at_css('.card-item__meta')
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `HomeTest` failures (no `.hero`).

- [ ] **Step 3: Card include and styles**

`_includes/card.liquid`:

```liquid
{% if include.external %}
  {% assign card_href = include.url %}
{% else %}
  {% assign card_href = include.url | relative_url %}
{% endif %}
<article class="card-item">
  <a class="card-item__link" href="{{ card_href }}"{% if include.external %} target="_blank" rel="noopener"{% endif %}>
    {% if include.img %}
      {% if include.img contains '/assets/img/' %}
        {% include figure.liquid path=include.img sizes="(min-width: 992px) 340px, (min-width: 576px) 45vw, 90vw" alt=include.title class="card-item__img" loading="lazy" %}
      {% else %}
        {% include figure.liquid path=include.img avoid_scaling=true alt=include.title class="card-item__img" loading="lazy" %}
      {% endif %}
    {% else %}
      <div class="card-item__img card-item__img--empty" aria-hidden="true"></div>
    {% endif %}
    {% if include.kind %}<span class="badge-kind">{{ include.kind }}</span>{% endif %}
    <h3 class="card-item__title">{{ include.title }}</h3>
  </a>
  {% if include.meta and include.meta != '' %}<p class="card-item__meta">{{ include.meta }}</p>{% endif %}
  {% if include.description %}<p class="card-item__desc">{{ include.description }}</p>{% endif %}
</article>
```

`_sass/_card.scss`:

```scss
@use "breakpoints" as bp;

.card-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: var(--space-8) var(--space-6);

  @media (max-width: bp.$lg - 0.02px) {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  @media (max-width: bp.$sm - 0.02px) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.card-item__link {
  display: block;
  color: inherit;
  text-decoration: none;

  &:hover .card-item__title,
  &:focus-visible .card-item__title {
    color: var(--accent);
  }

  &:hover img {
    filter: brightness(1.08);
  }
}

.card-item figure,
.card-item__img--empty {
  margin-bottom: var(--space-3);
}

.card-item img,
.card-item__img {
  display: block;
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 2px;
}

.card-item__img--empty {
  background: repeating-linear-gradient(135deg, var(--rule) 0 2px, transparent 2px 10px);
}

.card-item__title {
  font-family: var(--font-mono);
  font-size: var(--step-0);
  font-weight: 500;
  color: var(--head);
  text-shadow: none;
  margin: var(--space-2) 0 var(--space-1);
}

.card-item__meta {
  font-family: var(--font-mono);
  font-size: var(--step--1);
  color: var(--muted);
  margin: 0 0 var(--space-2);
}

.card-item__desc {
  font-size: 0.95rem;
  line-height: 1.5;
  margin: 0;
}
```

- [ ] **Step 4: Home layout, styles and content**

`_layouts/home.liquid`:

```liquid
---
layout: default
---
<section class="hero">
  {% if page.portrait %}
    {% assign portrait = page.portrait | prepend: '/assets/img/' %}
    <div class="hero__portrait">
      {% include figure.liquid path=portrait sizes="(min-width: 768px) 220px, 160px" alt="Portrait of Philipp Haslbauer" class="hero__img" loading="eager" %}
    </div>
  {% endif %}
  <div class="hero__text">
    <h1 class="display-name">{{ site.first_name }} {{ site.last_name }}</h1>
    <div class="hero__bio">{{ content }}</div>
    {% include links.liquid %}
  </div>
</section>

{% if site.data.featured.size > 0 %}
  <section class="featured" aria-labelledby="featured-label">
    <h2 class="section-label" id="featured-label">Selected</h2>
    <div class="card-grid">
      {% for item in site.data.featured %}
        {% include card.liquid url=item.url img=item.img kind=item.kind title=item.title meta=item.meta description=item.description external=item.external %}
      {% endfor %}
    </div>
  </section>
{% endif %}
```

`_sass/_home.scss`:

```scss
@use "breakpoints" as bp;

.hero {
  display: grid;
  grid-template-columns: 220px minmax(0, 1fr);
  gap: var(--space-8);
  align-items: end;

  @media (max-width: bp.$md - 0.02px) {
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-6);
  }
}

.hero__portrait {
  @media (max-width: bp.$md - 0.02px) {
    max-width: 160px;
  }
}

.hero__img {
  display: block;
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: 2px;
}

.display-name {
  font-size: var(--step-5);
  line-height: 1;
  margin-bottom: var(--space-3);

  @media (max-width: bp.$sm - 0.02px) {
    font-size: var(--step-4);
  }
}

.hero__bio p {
  max-width: 34em;
  font-size: var(--step-1);
  line-height: 1.5;
  margin: 0;
}
```

Append to `assets/css/main.scss`:

```scss
@use "card";
@use "home";
```

`_pages/about.md` (replace whole file):

```markdown
---
layout: home
title: about
permalink: /
portrait: me_25.jpg
---
Researcher, software developer, and interactive media artist based in Lucerne, Switzerland.
```

The bio is one sentence on purpose; Philipp supplies the longer text (spec: "Bio text to be supplied by Philipp").

Featured flags:
- `_projects/deus-in-machina.md` front matter: add `featured: true`, `featured_order: 1`, `featured_meta: "2024–2026 · Lucerne, Vienna"`.
- `_experiments/two.md` front matter: add `featured: true`, `featured_order: 3`, `year: 2023`; remove the stray `collection: demos` line.
- `_bibliography/papers.bib`, entry `haslbauer2025vrplanica`: add the fields
  `featured={true}, featured_order={2}, featured_title={VR Planica}, featured_description={Gaussian splatting workflows for immersive storytelling.},`

- [ ] **Step 5: Remove the old about layout and social icons**

```bash
git rm -q _layouts/about_cv.liquid _includes/social.liquid
git grep -n "social.liquid\|about_cv" -- _layouts _includes _pages || echo "no references"
```

Expected: `no references`.

- [ ] **Step 6: Run to verify pass**

Run: `bin/check`
Expected: all pass.

- [ ] **Step 7: Commit**

```bash
git add -A _includes/card.liquid _layouts/home.liquid _layouts/about_cv.liquid _includes/social.liquid _sass/_card.scss _sass/_home.scss assets/css/main.scss _pages/about.md _projects/deus-in-machina.md _experiments/two.md _bibliography/papers.bib test/site/home_test.rb test/includes/card_test.rb
git commit -m "Add card component and featured home page"
```

- [ ] **Step 8: Empty-featured guard check** (temporary edits, reverted at the end)

```bash
sed -i '' 's/^featured: true$/featured: false/' _projects/deus-in-machina.md _experiments/two.md
sed -i '' 's/featured={true}/featured={false}/' _bibliography/papers.bib
bundle exec jekyll build --quiet && grep -c 'featured-label' _site/index.html
git checkout HEAD -- _projects/deus-in-machina.md _experiments/two.md _bibliography/papers.bib
bin/check
```

Expected: the `grep -c` prints `0` (no "Selected" section when nothing is featured); after the revert, `bin/check` is green again.

- [ ] **Step 9: REVIEW CHECKPOINT 1 (Philipp)**

Serve the site (`bundle exec jekyll serve --port 4001`). With the Playwright MCP, take full-page screenshots of `/` and `/publications/` (chrome only) at 1440×900 and 390×844, save them to `.playwright-mcp/shots/review1/` and copy them to `/Volumes/T7 Shield/Temp/website-redesign/review1/`. Show them to Philipp next to the "before" screenshots with these criteria:
1. Does the home page match the chosen mockup (layout A, type C, palette B3)?
2. Is the hierarchy clear: name, then bio, then links, then "Selected"?
3. On the phone screenshot: is the name visible without scrolling, and do the cards stack cleanly?
4. Is it obvious what is clickable (pink in-text links, mint nav and card titles)?

Stop and wait for approval or change requests before Task 9.

---

### Task 9: Works, experiments and their detail pages

**Files:**
- Modify: `_pages/projects.md`, `_pages/experiments.md`, `_layouts/page.liquid`, `_layouts/experiment.liquid`, `_layouts/demo.liquid`, `_experiments/one.md`, `assets/css/main.scss`
- Create: `_sass/_prose.scss`, `_sass/_experiment.scss`
- Delete: `_includes/projects.liquid`
- Test: `test/site/works_experiments_test.rb`

**Interfaces:**
- Consumes: `card.liquid` (Task 8).
- Produces: `.prose` (reading-width column, used by work pages here and posts in Task 11).

- [ ] **Step 1: Write the failing tests**

```ruby
require_relative '../test_helper'

class WorksExperimentsTest < Minitest::Test
  include SiteHelpers

  def test_works_shows_only_non_empty_categories
    labels = page('/works/').css('.work-category .section-label').map { |h| h.text.strip }
    assert_equal ['exhibited'], labels
  end

  def test_works_card_links_to_work_page
    assert_equal '/works/deus-in-machina/', page('/works/').at_css('.card-item a')['href']
  end

  def test_work_page_marks_works_nav_active
    assert_equal 'works', page('/works/deus-in-machina/').at_css('#site-nav a.active').text.strip
  end

  def test_experiments_lists_all_visible_experiments
    titles = page('/experiments/').css('.card-item__title').map { |t| t.text.strip }
    assert_equal 3, titles.size
    assert_includes titles, 'Morse Chatbot'
    refute_includes titles, 'The Scriptorium'
  end

  def test_experiment_cards_do_not_use_generated_srcset
    card = page('/experiments/').css('.card-item').find { |c| c.at_css('.card-item__title').text.include?('Morse') }
    assert_equal '/assets/experiments/morse-chatbot/preview.png', card.at_css('img')['src']
    assert_nil card.at_css('source')
  end

  def test_experiment_page_embeds_iframe
    assert page('/experiments/morse-chatbot/').at_css('iframe[src="/assets/experiments/morse-chatbot/index.html"]')
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: failures for empty categories, `/works/` card markup, morse srcset.

- [ ] **Step 3: Rewrite the listing pages**

`_pages/projects.md` (whole file):

```liquid
---
layout: page
title: works
permalink: /works/
description: Installations and artworks.
nav: true
nav_order: 1
display_categories: [exhibited, in preparation, past]
---
{% for category in page.display_categories %}
  {% assign items = site.projects | where: 'category', category | sort: 'importance', 'last' %}
  {% if items.size > 0 %}
    <section class="work-category" id="{{ category | slugify }}">
      <h2 class="section-label">{{ category }}</h2>
      <div class="card-grid">
        {% for p in items %}
          {% include card.liquid url=p.url img=p.img title=p.title meta=p.year description=p.description %}
        {% endfor %}
      </div>
    </section>
  {% endif %}
{% endfor %}
```

`_pages/experiments.md` (whole file):

```liquid
---
layout: page
permalink: /experiments/
title: experiments
description: Creative experiments, and projects to be.
nav: true
nav_order: 3
---
{% assign items = site.experiments | sort: 'importance', 'last' %}
<div class="card-grid">
  {% for e in items %}
    {% include card.liquid url=e.url img=e.img title=e.title meta=e.year description=e.description %}
  {% endfor %}
</div>
```

`_experiments/one.md`: change `img: /assets/img/demos/one-preview.jpg` to `img: /assets/img/demos/one-preview.png` and add `importance: 3`. `_experiments/two.md`: add `importance: 4`.

- [ ] **Step 4: Detail layouts**

`_layouts/page.liquid` (whole file):

```liquid
---
layout: default
---
<header class="page-header">
  <h1 class="page-title">{{ page.title }}</h1>
  {% if page.description %}<p class="lede">{{ page.description }}</p>{% endif %}
</header>

{% if page.collection == 'projects' %}
  <article class="prose">{{ content }}</article>
{% else %}
  {{ content }}
{% endif %}

{% if page.related_publications %}
  <h2 class="section-label">References</h2>
  <div class="publications">{% bibliography --cited_in_order %}</div>
{% endif %}
```

`_layouts/experiment.liquid` (whole file):

```liquid
---
layout: default
---
<header class="page-header">
  <h1 class="page-title">{{ page.title }}</h1>
  {% if page.year != '' %}<p class="meta">{{ page.year }}</p>{% endif %}
  {% if page.description != '' %}<p class="lede">{{ page.description }}</p>{% endif %}
</header>

<div class="experiment-frame">
  <iframe
    src="/assets/experiments/{{ page.experiment }}/index.html"
    title="{{ page.title }}"
    allowfullscreen
    allow="cross-origin-isolated"
  ></iframe>
</div>
```

`_layouts/demo.liquid` (whole file):

```liquid
---
layout: default
---
<script async src="https://unpkg.com/es-module-shims@1.6.3/dist/es-module-shims.js"></script>
<script type="importmap">
  {
    "imports": {
      "three": "https://unpkg.com/three@0.152.2/build/three.module.js",
      "three/addons/": "https://unpkg.com/three@0.152.2/examples/jsm/",
      "dat.gui": "https://cdn.jsdelivr.net/npm/dat.gui@0.7.9/build/dat.gui.module.js"
    }
  }
</script>

<header class="page-header">
  <h1 class="page-title">{{ page.title }}</h1>
  {% if page.description %}<p class="lede">{{ page.description }}</p>{% endif %}
</header>

<div class="demo-body prose">{{ content }}</div>
```

The demo scripts mount into `#demo-container` (inside `{{ content }}`), so the old `<div id="main">` wrapper is not needed.

`_sass/_prose.scss`:

```scss
.prose {
  max-width: var(--measure);

  h2 {
    font-size: var(--step-1);
    margin-top: var(--space-12);
  }

  h3 {
    font-size: var(--step-0);
    margin-top: var(--space-8);
  }

  img {
    display: block;
    width: 100%;
    margin: var(--space-6) 0 var(--space-2);
    border-radius: 2px;
  }

  em:only-child,
  img + em {
    display: block;
    font-family: var(--font-mono);
    font-style: normal;
    font-size: var(--step--1);
    color: var(--muted);
  }

  ul,
  ol {
    padding-left: 1.2em;
  }

  li {
    margin-bottom: var(--space-2);
  }

  strong {
    color: var(--head);
    font-weight: 600;
  }

  blockquote {
    border-left: 2px solid var(--accent);
    margin: var(--space-6) 0;
    padding-left: var(--space-4);
    color: var(--muted);
  }
}
```

`_sass/_experiment.scss`:

```scss
.experiment-frame {
  border: 1px solid var(--rule);
  border-radius: 2px;
  overflow: hidden;

  iframe {
    display: block;
    width: 100%;
    height: min(720px, 80vh);
    border: 0;
  }
}
```

Append to `assets/css/main.scss`:

```scss
@use "prose";
@use "experiment";
```

```bash
git rm -q _includes/projects.liquid
```

- [ ] **Step 5: Run to verify pass**

Run: `bin/check`
Expected: all tests pass; the `one-preview.jpg` broken image is gone from the html-proofer report (only the blog link failures logged in Task 5 remain).

- [ ] **Step 6: Commit**

```bash
git add -A _pages/projects.md _pages/experiments.md _layouts/page.liquid _layouts/experiment.liquid _layouts/demo.liquid _includes/projects.liquid _experiments _sass/_prose.scss _sass/_experiment.scss assets/css/main.scss test/site
git commit -m "Restyle works and experiments with shared cards; hide empty categories"
```

---

### Task 10: Publications

**Files:**
- Modify: `_layouts/bib.liquid` (whole file), `_includes/bib_search.liquid`, `_bibliography/papers.bib`, `assets/css/main.scss`
- Create: `_sass/_publications.scss`
- Delete: `_plugins/remove-accents.rb`, `_plugins/file-exists.rb` (only if `git grep` shows no other use)
- Test: `test/site/publications_test.rb`

**Interfaces:**
- Consumes: `.chip`, `.chips`, `.section-label` (Task 6); `common.js` panel toggling (classes `abstract`, `award`, `bibtex`, `hidden`, `open`); `bibsearch.js` (classes `unloaded`, selector `.bibliography > li`, input `#bibsearch`).

- [ ] **Step 1: Write the failing tests**

```ruby
require_relative '../test_helper'

class PublicationsTest < Minitest::Test
  include SiteHelpers

  def pubs
    @pubs ||= page('/publications/')
  end

  def test_entries_use_pub_markup
    assert_equal 7, pubs.css('.bibliography > li .pub').size
    assert pubs.css('.pub__title').all? { |t| !t.text.strip.empty? }
  end

  def test_links_render_as_chips
    chips = pubs.css('.pub .chips a')
    refute_empty chips
    assert chips.all? { |a| a['class'].split.include?('chip') }
  end

  def test_doi_links_are_not_double_prefixed
    pubs.css('a[href*="doi.org"]').each { |a| refute_match(%r{doi\.org/https?://}, a['href']) }
  end

  def test_no_raw_latex_in_abstracts
    refute_match(/\\textit/, pubs.text)
  end

  def test_proceedings_periodical_has_no_leading_comma
    pubs.css('.pub__periodical').each { |p| refute_match(/\A\s*,/, p.text) }
  end

  def test_filter_input_present
    assert pubs.at_css('input#bibsearch.bibsearch-form-input')
  end

  def test_no_icon_fonts_or_badges
    assert_empty pubs.css('i.fa-solid, .badges, .altmetric-embed')
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `PublicationsTest` failures (no `.pub`, `\textit`, DOI double prefix, leading comma).

- [ ] **Step 3: Fix bibliography content**

In `_bibliography/papers.bib`:
- Entry `haslbauer2025aijesus`, `abstract`: replace `"\textit{Deus in Machina"}` with `"Deus in Machina"`.
- Entry `GSvsPhotogrammetry`, `additional_info`: remove the leading `. ` so it reads `*More Information* can be [found here](https://irc-hslu.github.io/GSvsPhotogrammetry/).`
- Entry `nguyen2024volumetric`: replace `doi={https://doi.org/10.1145/3641825.368969}` with `doi={10.1145/3641825.368969}`. The DOI suffix looks one digit short (ACM DOIs in that volume have seven digits after the dot); record it in `LOG.md` as a question for Philipp and do not guess.

- [ ] **Step 4: Rewrite `_layouts/bib.liquid`**

```liquid
---
---
{% assign has_thumb = false %}
{% if site.enable_publication_thumbnails and entry.preview %}{% assign has_thumb = true %}{% endif %}
<div class="pub{% unless has_thumb %} pub--no-thumb{% endunless %}">
  {% if has_thumb %}
    <div class="pub__thumb">
      {% if entry.preview contains '://' %}
        <img src="{{ entry.preview }}" alt="" loading="lazy">
      {% else %}
        {% assign entry_path = entry.preview | prepend: '/assets/img/publication_preview/' %}
        {% include figure.liquid loading="lazy" path=entry_path sizes="160px" avoid_scaling=true alt="" %}
      {% endif %}
    </div>
  {% endif %}

  <div id="{{ entry.key }}" class="pub__body">
    {% if entry.abbr %}<span class="badge-kind pub__venue">{{ entry.abbr }}</span>{% endif %}
    <h3 class="pub__title">{{ entry.title }}</h3>

    <p class="pub__authors">
      {% assign author_array_size = entry.author_array | size %}
      {% assign author_array_limit = author_array_size %}
      {% if site.max_author_limit and author_array_size > site.max_author_limit %}
        {% assign author_array_limit = site.max_author_limit %}
      {% endif %}
      {%- for author in entry.author_array limit: author_array_limit -%}
        {%- assign author_last_name = author.last | regex_replace: '[*∗†‡§¶‖&^]', '' -%}
        {%- assign author_last_html = author.last | regex_replace: '([*∗†‡§¶‖&^]+)', '<sup>\1</sup>' -%}
        {% assign author_is_self = false %}
        {% if site.scholar.last_name contains author_last_name and site.scholar.first_name contains author.first %}
          {% assign author_is_self = true %}
        {% endif %}
        {%- if forloop.length > 1 and forloop.first == false -%}
          {%- if forloop.length > 2 %}, {% else %} {% endif -%}
        {%- endif -%}
        {%- if forloop.last and forloop.length > 1 and author_array_limit == author_array_size %}and {% endif -%}
        {%- if author_is_self -%}
          <em class="pub__self">{{ author.first }} {{ author_last_html }}</em>
        {%- else -%}
          {{ author.first }} {{ author_last_html }}
        {%- endif -%}
      {%- endfor -%}
      {%- assign more_authors = author_array_size | minus: author_array_limit -%}
      {% if more_authors > 0 %}
        {%- assign more_authors_hide = more_authors | append: ' more author' -%}
        {%- if more_authors > 1 %}{% assign more_authors_hide = more_authors_hide | append: 's' %}{% endif -%}
        {% assign more_authors_show = '' %}
        {%- for author in entry.author_array offset: author_array_limit -%}
          {% assign more_authors_show = more_authors_show | append: author.first | append: ' ' | append: author.last %}
          {% unless forloop.last %}{% assign more_authors_show = more_authors_show | append: ', ' %}{% endunless %}
        {%- endfor -%}
        , and
        <button
          type="button"
          class="more-authors"
          data-more="{{ more_authors_show | escape }}"
          onclick="this.replaceWith(document.createTextNode(this.dataset.more))"
        >{{ more_authors_hide }}</button>
      {% endif %}
    </p>

    {% assign proceedings = 'inproceedings,incollection,proceedings' | split: ',' %}
    {% assign thesis = 'thesis,mastersthesis,phdthesis' | split: ',' %}
    {% assign periodical = '' %}
    {% if entry.type == 'article' and entry.journal %}
      {% capture periodical %}<em>{{ entry.journal }}</em>{% endcapture %}
    {% elsif proceedings contains entry.type and entry.booktitle %}
      {% capture periodical %}<em>In {{ entry.booktitle }}</em>{% endcapture %}
    {% elsif thesis contains entry.type and entry.school %}
      {% capture periodical %}<em>{{ entry.school }}</em>{% endcapture %}
    {% endif %}
    {% assign parts = '' | split: '' %}
    {% if periodical != '' %}{% assign parts = parts | push: periodical %}{% endif %}
    {% if entry.location %}{% assign parts = parts | push: entry.location %}{% endif %}
    {% if entry.additional_info %}
      {% assign info = entry.additional_info | markdownify | remove: '<p>' | remove: '</p>' | strip %}
      {% assign parts = parts | push: info %}
    {% endif %}
    {% capture pub_date %}{% if entry.month %}{{ entry.month | capitalize }} {% endif %}{{ entry.year }}{% endcapture %}
    {% assign pub_date = pub_date | strip %}
    {% if pub_date != '' %}{% assign parts = parts | push: pub_date %}{% endif %}
    <p class="pub__periodical">{{ parts | join: ', ' }}</p>
    {% if entry.note %}<p class="pub__periodical">{{ entry.note }}</p>{% endif %}

    <div class="chips">
      {% if entry.award %}<a class="award chip" role="button">{% if entry.award_name %}{{ entry.award_name }}{% else %}Awarded{% endif %}</a>{% endif %}
      {% if entry.abstract %}<a class="abstract chip" role="button">Abstract</a>{% endif %}
      {% if entry.doi %}<a class="chip" href="https://doi.org/{{ entry.doi | remove_first: 'https://doi.org/' }}">DOI</a>{% endif %}
      {% if entry.arxiv %}<a class="chip" href="https://arxiv.org/abs/{{ entry.arxiv }}">arXiv</a>{% endif %}
      {% if entry.bibtex_show %}<a class="bibtex chip" role="button">BibTeX</a>{% endif %}
      {% assign link_kinds = 'html,pdf,supp,poster,slides' | split: ',' %}
      {% for kind in link_kinds %}
        {% assign target = entry[kind] %}
        {% if target %}
          {% unless target contains '://' %}
            {% if kind == 'html' %}{% assign target = target | prepend: '/assets/html/' | relative_url %}{% else %}{% assign target = target | prepend: '/assets/pdf/' | relative_url %}{% endif %}
          {% endunless %}
          {% case kind %}{% when 'html' %}{% assign label = 'Website' %}{% when 'pdf' %}{% assign label = 'PDF' %}{% when 'supp' %}{% assign label = 'Supplement' %}{% when 'poster' %}{% assign label = 'Poster' %}{% when 'slides' %}{% assign label = 'Slides' %}{% endcase %}
          <a class="chip" href="{{ target }}">{{ label }}</a>
        {% endif %}
      {% endfor %}
      {% if entry.video %}<a class="chip" href="{{ entry.video }}">Video</a>{% endif %}
      {% if entry.code %}<a class="chip" href="{{ entry.code }}">Code</a>{% endif %}
      {% if entry.website %}<a class="chip" href="{{ entry.website }}">Project</a>{% endif %}
    </div>

    {% if entry.award %}<div class="award hidden"><p>{{ entry.award | markdownify }}</p></div>{% endif %}
    {% if entry.abstract %}<div class="abstract hidden"><p>{{ entry.abstract }}</p></div>{% endif %}
    {% if entry.bibtex_show %}
      <div class="bibtex hidden">
        {% highlight bibtex %}
        {{- entry.bibtex | hideCustomBibtex -}}
        {% endhighlight %}
      </div>
    {% endif %}
  </div>
</div>
```

`common.js` finds panels with `$(this).parent().parent()`: the chip's parent is `.chips`, whose parent is `.pub__body`, which contains the `.hidden` panels. No JS change needed.

`_includes/bib_search.liquid`:

```liquid
{% if site.bib_search %}
  <script src="{{ '/assets/js/bibsearch.js' | relative_url | bust_file_cache }}" type="module"></script>
  <label class="sr-only" for="bibsearch">Filter publications</label>
  <input type="search" id="bibsearch" spellcheck="false" autocomplete="off" class="bibsearch-form-input" placeholder="Filter by title, author, venue">
{% endif %}
```

`_sass/_publications.scss`:

```scss
@use "breakpoints" as bp;

.publications {
  h2.bibliography {
    font-family: var(--font-mono);
    font-size: var(--step--1);
    font-weight: 400;
    letter-spacing: 0.14em;
    color: var(--accent);
    text-shadow: none;
    margin: var(--space-12) 0 0;
  }

  ol.bibliography {
    list-style: none;
    padding: 0;
    margin: 0;

    > li {
      border-top: 1px solid var(--rule);
      padding: var(--space-6) 0;
    }
  }
}

.pub {
  display: grid;
  grid-template-columns: 160px minmax(0, 1fr);
  gap: var(--space-6);

  @media (max-width: bp.$sm - 0.02px) {
    grid-template-columns: 88px minmax(0, 1fr);
    gap: var(--space-4);
  }
}

.pub--no-thumb {
  grid-template-columns: minmax(0, 1fr);
}

.pub__thumb img {
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 2px;
}

.pub__venue {
  margin-bottom: var(--space-2);
}

.pub__title {
  font-size: var(--step-0);
  font-weight: 500;
  text-shadow: none;
  margin: 0 0 var(--space-1);
}

.pub__authors,
.pub__periodical {
  margin: 0 0 var(--space-1);
  font-size: 0.95rem;
}

.pub__periodical {
  color: var(--muted);
}

.pub__self {
  font-style: normal;
  color: var(--head);
}

.more-authors {
  background: none;
  border: 0;
  border-bottom: 1px dashed var(--muted);
  padding: 0;
  color: var(--muted);
  font: inherit;
  cursor: pointer;
}

.pub .hidden {
  display: none;

  &.open {
    display: block;
    margin-top: var(--space-3);
    font-size: 0.95rem;
  }
}

.bibsearch-form-input {
  width: 100%;
  max-width: 360px;
  background: transparent;
  color: var(--text);
  border: 1px solid var(--rule);
  border-radius: 0;
  font-family: var(--font-mono);
  font-size: var(--step--1);
  padding: var(--space-2) var(--space-3);

  &:focus {
    border-color: var(--accent);
    outline: none;
  }
}

.unloaded {
  display: none !important;
}

::highlight(search) {
  background-color: var(--accent);
  color: var(--bg);
}
```

Append `@use "publications";` to `assets/css/main.scss`.

- [ ] **Step 5: Remove now-unused plugins**

```bash
git grep -n "remove_accents\|file_exists" -- _layouts _includes _pages || git rm -q _plugins/remove-accents.rb _plugins/file-exists.rb
```

- [ ] **Step 6: Run to verify pass**

Run: `bin/check`
Expected: all pass.

- [ ] **Step 7: Browser check of interactions**

On `/publications/` via Playwright MCP: click "Abstract" on the first entry (panel opens), click "BibTeX" on an entry with `bibtex_show` (abstract closes, BibTeX opens), click "1 more author" (full name list appears), type "planica" into the filter (only one entry left, the matching text highlighted). Record the outcome in `LOG.md`.

- [ ] **Step 8: Commit**

```bash
git add -A _layouts/bib.liquid _includes/bib_search.liquid _bibliography/papers.bib _sass/_publications.scss assets/css/main.scss _plugins test/site/publications_test.rb
git commit -m "Restyle publications; fix DOI prefix, raw LaTeX and proceedings periodical"
```

---

### Task 11: Blog list and post layout — then REVIEW CHECKPOINT 2

**Files:**
- Modify: `_pages/blog.md` (whole file), `_layouts/post.liquid` (whole file), `_includes/pagination.liquid`, `assets/css/main.scss`
- Create: `_sass/_row.scss`, `_sass/_code.scss` (generated)
- Test: `test/site/blog_test.rb`

**Interfaces:**
- Consumes: `.prose` (Task 9), `.chip`, `.meta`, `.section-label` (Task 6).
- Produces: `.row-list`, `.row-item`, `.row-item__thumb`, `.row-item__title`, `.row-item__desc`.

- [ ] **Step 1: Write the failing tests**

```ruby
require_relative '../test_helper'

class BlogTest < Minitest::Test
  include SiteHelpers

  def test_blog_lists_posts_as_rows
    rows = page('/blog/').css('.row-list > .row-item')
    assert_operator rows.size, :>=, 3
    assert rows.all? { |r| r.at_css('.row-item__title a') }
  end

  def test_substack_items_are_marked_and_open_externally
    row = page('/blog/').css('.row-item').find { |r| r.at_css('.chip')&.text&.include?('substack') }
    assert row, 'expected at least one Substack row'
    assert_match %r{\Ahttps://}, row.at_css('.row-item__title a')['href']
    assert_equal '_blank', row.at_css('.row-item__title a')['target']
  end

  def test_no_tag_or_category_links
    assert_empty page('/blog/').css('a[href*="/blog/tag/"], a[href*="/blog/category/"]')
  end

  def test_post_has_toc_before_body_and_reading_width
    post = page('/blog/2023/controlling-diffusion/')
    assert post.at_css('article.prose nav.toc ul')
    assert post.at_css('.page-header .meta').text.include?('min read')
  end

  def test_code_is_highlighted_with_dark_theme
    assert page('/blog/2023/controlling-diffusion/').at_css('.highlight')
    assert_match(/\.highlight/, css)
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `BlogTest` failures.

- [ ] **Step 3: Blog list**

`_pages/blog.md` (whole file):

```liquid
---
layout: default
permalink: /blog/
title: blog
nav: true
nav_order: 4
pagination:
  enabled: true
  collection: posts
  permalink: /page/:num/
  per_page: 10
  sort_field: date
  sort_reverse: true
  trail:
    before: 1
    after: 3
---
<header class="page-header">
  <h1 class="page-title">{{ page.title }}</h1>
  {% if site.blog_description %}<p class="lede">{{ site.blog_description }}</p>{% endif %}
</header>

{% if page.pagination.enabled %}{% assign postlist = paginator.posts %}{% else %}{% assign postlist = site.posts %}{% endif %}
<ol class="row-list">
  {% for post in postlist %}
    {% assign external = false %}
    {% assign href = post.url | relative_url %}
    {% if post.redirect contains '://' %}{% assign external = true %}{% assign href = post.redirect %}{% endif %}
    <li class="row-item{% unless post.thumbnail %} row-item--no-thumb{% endunless %}">
      {% if post.thumbnail %}
        <a class="row-item__thumb" href="{{ href }}" tabindex="-1" aria-hidden="true"{% if external %} target="_blank" rel="noopener"{% endif %}>
          <img src="{{ post.thumbnail | relative_url }}" alt="" loading="lazy">
        </a>
      {% endif %}
      <div>
        <h2 class="row-item__title">
          <a href="{{ href }}"{% if external %} target="_blank" rel="noopener"{% endif %}>{{ post.title }}</a>
        </h2>
        {% if post.description %}<p class="row-item__desc">{{ post.description }}</p>{% endif %}
        <p class="meta">
          {{ post.date | date: '%B %-d, %Y' }}
          {% if post.external_source %}<span class="chip">{{ post.external_source | downcase }} ↗</span>{% endif %}
        </p>
      </div>
    </li>
  {% endfor %}
</ol>

{% if page.pagination.enabled %}{% include pagination.liquid %}{% endif %}
```

Check `_includes/pagination.liquid` for icon classes (`git grep -n "fa-\|ti-" _includes/pagination.liquid`) and replace any icon with the text `←` / `→`.

`_sass/_row.scss`:

```scss
@use "breakpoints" as bp;

.row-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.row-item {
  display: grid;
  grid-template-columns: 200px minmax(0, 1fr);
  gap: var(--space-6);
  padding: var(--space-6) 0;
  border-top: 1px solid var(--rule);

  @media (max-width: bp.$sm - 0.02px) {
    grid-template-columns: 96px minmax(0, 1fr);
    gap: var(--space-4);
  }
}

.row-item--no-thumb {
  grid-template-columns: minmax(0, 1fr);
}

.row-item__thumb img {
  display: block;
  width: 100%;
  aspect-ratio: 4 / 3;
  object-fit: cover;
  border-radius: 2px;
}

.row-item__title {
  font-size: var(--step-0);
  font-weight: 500;
  margin: 0 0 var(--space-1);

  a {
    color: var(--head);
    text-decoration: none;

    &:hover,
    &:focus-visible {
      color: var(--accent);
    }
  }
}

.row-item__desc {
  margin: 0 0 var(--space-2);
}

.row-item .meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--space-3);
  margin: 0;
}
```

- [ ] **Step 4: Post layout and code theme**

`_layouts/post.liquid` (whole file):

```liquid
---
layout: default
---
<article class="post prose">
  <header class="page-header">
    <h1 class="page-title">{{ page.title }}</h1>
    {% assign read_time = content | number_of_words | divided_by: 180 | plus: 1 %}
    <p class="meta">{{ page.date | date: '%B %-d, %Y' }} · {{ read_time }} min read</p>
    {% if page.description %}<p class="lede">{{ page.description }}</p>{% endif %}
  </header>

  {% if page.toc %}
    <nav class="toc" aria-label="Contents">
      <p class="section-label">Contents</p>
      {% toc %}
    </nav>
  {% endif %}

  {{ content }}
</article>
```

Generate the code theme and scope it:

```bash
bundle exec rougify style github.dark > _sass/_code.scss
cat >> _sass/_code.scss <<'EOF'

div.highlight {
  background: #0b1a11;
  border: 1px solid var(--rule);
  border-radius: 2px;
  padding: var(--space-4);
  overflow-x: auto;
  margin: var(--space-6) 0;
}

pre.highlight {
  background: transparent;
  margin: 0;
}

code,
pre {
  font-family: var(--font-mono);
  font-size: var(--step--1);
}

:not(pre) > code {
  color: var(--head);
}

.toc {
  margin-bottom: var(--space-8);

  ul {
    list-style: none;
    padding-left: 0;
    font-family: var(--font-mono);
    font-size: var(--step--1);
  }

  ul ul {
    padding-left: var(--space-4);
  }
}
EOF
```

Append to `assets/css/main.scss`:

```scss
@use "row";
@use "code";
```

- [ ] **Step 5: Run to verify pass**

Run: `bin/check`
Expected: all tests pass and html-proofer reports 0 failures (the old tag/year links are gone). From here on `bin/check` must be fully green. If `test_post_has_toc_before_body_and_reading_width` fails because `{% toc %}` outputs nothing in a layout, replace the tag with `{{ content | toc_only }}` (jekyll-toc filter) and rerun.

- [ ] **Step 6: Commit**

```bash
git add -A _pages/blog.md _layouts/post.liquid _includes/pagination.liquid _sass/_row.scss _sass/_code.scss assets/css/main.scss test/site/blog_test.rb
git commit -m "Restyle blog list and posts; TOC above body; dark code theme"
```

- [ ] **Step 7: REVIEW CHECKPOINT 2 (Philipp)**

Screenshots at 1440×900 and 390×844 (full page) of `/works/`, `/works/deus-in-machina/`, `/experiments/`, `/experiments/morse-chatbot/`, `/publications/`, `/blog/`, `/blog/2023/controlling-diffusion/`, saved to `.playwright-mcp/shots/review2/` and copied to `/Volumes/T7 Shield/Temp/website-redesign/review2/`. Present them next to the "before" screenshots. Criteria:
1. Do works, experiments, publications and blog look like one system (same labels, chips, card and row rhythm)?
2. Publications: can you scan year, venue, title and links quickly? Are the thumbnails helping or noise?
3. Blog post: is the reading width comfortable, and does the code block read well on the dark background?
4. Phone: anything cramped, cut off or scrolling sideways?

Stop and wait for approval or change requests before Task 12.

---

### Task 12: CV page with print stylesheet — then REVIEW CHECKPOINT 3

**Files:**
- Modify: `_layouts/cv.liquid` (whole file), `_pages/cv.md` (whole file), `assets/css/main.scss`
- Create: `_sass/_cv.scss`, `_sass/_print.scss`
- Delete: `_includes/cv/`, `_includes/resume/`
- Test: `test/site/cv_test.rb`

**Interfaces:**
- Consumes: `_data/cv.yml` (sections with `title`, `contents[]`; items with `year`, `location`, `title`, `institution`, `event`, `description` as string or list).

- [ ] **Step 1: Write the failing tests**

```ruby
require 'yaml'
require_relative '../test_helper'

class CvTest < Minitest::Test
  include SiteHelpers

  def cv
    @cv ||= page('/cv/')
  end

  def data
    YAML.load_file(File.expand_path('../../_data/cv.yml', __dir__))
  end

  def test_every_section_and_entry_is_rendered
    sections = data.reject { |s| s['contents'].nil? || s['contents'].empty? }
    assert_equal sections.map { |s| s['title'] }, cv.css('.cv-section > .section-label').map { |h| h.text.strip }
    assert_equal sections.sum { |s| s['contents'].size }, cv.css('.cv-entry').size
  end

  def test_string_and_list_descriptions_both_render
    assert cv.css('.cv-entry__items li').any?
    assert cv.css('.cv-entry__desc').any? { |p| p.text.include?('Watch here') }
  end

  def test_print_button_and_print_styles
    assert_equal 'window.print()', cv.at_css('button.cv-print')['onclick']
    assert_match(/@media print/, css)
    assert_match(/break-inside:\s*avoid/, css)
  end

  def test_no_icon_markup
    assert_empty cv.css('i[class*="fa-"]')
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `CvTest` failures.

- [ ] **Step 3: Implement**

`_pages/cv.md`:

```markdown
---
layout: cv
permalink: /cv/
title: cv
description: Curriculum vitae of Philipp Haslbauer.
nav: false
---
```

`_layouts/cv.liquid`:

```liquid
---
layout: default
---
<header class="page-header cv-header">
  <div>
    <h1 class="page-title">{{ page.title }}</h1>
    <p class="cv-print-only">{{ site.first_name }} {{ site.last_name }} · {{ site.url | remove: 'https://' }}</p>
  </div>
  <button type="button" class="chip cv-print" onclick="window.print()">Download PDF</button>
</header>

<div class="cv">
  {% for section in site.data.cv %}
    {% if section.contents == nil or section.contents == empty %}{% continue %}{% endif %}
    <section class="cv-section" id="{{ section.title | slugify }}">
      <h2 class="section-label">{{ section.title }}</h2>
      <ol class="cv-list">
        {% for item in section.contents %}
          <li class="cv-entry">
            <div class="cv-entry__when">
              {% if item.year %}<span class="cv-entry__year">{{ item.year }}</span>{% endif %}
              {% if item.location %}<span class="cv-entry__where">{{ item.location }}</span>{% endif %}
            </div>
            <div class="cv-entry__body">
              {% if item.title %}<h3 class="cv-entry__title">{{ item.title }}</h3>{% endif %}
              {% assign org = item.institution | default: item.event %}
              {% if org %}<p class="cv-entry__org">{{ org }}</p>{% endif %}
              {% if item.description %}
                {% assign desc_start = item.description | jsonify | slice: 0 %}
                {% if desc_start == '[' %}
                  <ul class="cv-entry__items">
                    {% for d in item.description %}{% if d %}<li>{{ d }}</li>{% endif %}{% endfor %}
                  </ul>
                {% else %}
                  <p class="cv-entry__desc">{{ item.description }}</p>
                {% endif %}
              {% endif %}
            </div>
          </li>
        {% endfor %}
      </ol>
    </section>
  {% endfor %}
</div>
```

`_sass/_cv.scss`:

```scss
@use "breakpoints" as bp;

.cv-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: var(--space-4);
}

.cv-print-only {
  display: none;
}

.cv-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.cv-entry {
  display: grid;
  grid-template-columns: 120px minmax(0, 1fr);
  gap: var(--space-6);
  padding: var(--space-4) 0;
  border-top: 1px solid var(--rule);

  @media (max-width: bp.$sm - 0.02px) {
    grid-template-columns: minmax(0, 1fr);
    gap: var(--space-1);
  }
}

.cv-entry__when {
  font-family: var(--font-mono);
  font-size: var(--step--1);
  display: flex;
  flex-direction: column;
}

.cv-entry__year {
  color: var(--accent);
}

.cv-entry__where {
  color: var(--muted);
}

.cv-entry__title {
  font-size: var(--step-0);
  font-weight: 500;
  margin: 0 0 var(--space-1);
}

.cv-entry__org {
  margin: 0 0 var(--space-1);
}

.cv-entry__items,
.cv-entry__desc {
  margin: 0;
  font-size: 0.95rem;
}

.cv-entry__items {
  padding-left: 1.1em;
}
```

`_sass/_print.scss`:

```scss
@media print {
  @page {
    size: A4;
    margin: 16mm 14mm;
  }

  :root {
    --bg: #fff;
    --text: #111;
    --head: #000;
    --accent: #000;
    --muted: #444;
    --rule: #bbb;
    --glow: none;
  }

  body {
    font-size: 10.5pt;
  }

  .site-header,
  .site-footer,
  .skip-link,
  .cv-print {
    display: none !important;
  }

  .site-main {
    padding: 0;
  }

  .cv-print-only {
    display: block;
    font-family: var(--font-mono);
    font-size: 9pt;
  }

  a {
    color: inherit;
    text-decoration: none;
  }

  .cv-entry {
    break-inside: avoid;
  }

  .section-label {
    break-after: avoid;
    margin-top: 8mm;
  }
}
```

Append to `assets/css/main.scss`:

```scss
@use "cv";
@use "print";
```

```bash
git rm -rq _includes/cv _includes/resume
```

- [ ] **Step 4: Run to verify pass**

Run: `bin/check`
Expected: all pass.

- [ ] **Step 5: Print to PDF**

With `bundle exec jekyll serve --port 4001` running, print with headless Chrome (Playwright's `page.pdf` only works headless):

```bash
mkdir -p .playwright-mcp/shots/review3
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --no-pdf-header-footer \
  --print-to-pdf=.playwright-mcp/shots/review3/cv.pdf http://localhost:4001/cv/
cp .playwright-mcp/shots/review3/cv.pdf "/Volumes/T7 Shield/Temp/website-redesign/review3/"
```

- [ ] **Step 6: Commit**

```bash
git add -A _layouts/cv.liquid _pages/cv.md _includes/cv _includes/resume _sass/_cv.scss _sass/_print.scss assets/css/main.scss test/site/cv_test.rb
git commit -m "Add CV page from cv.yml with A4 print stylesheet"
```

- [ ] **Step 7: REVIEW CHECKPOINT 3 (Philipp)**

Send screenshots of `/cv/` (1440 and 390) and the PDF. Criteria:
1. Is the CV complete and in the right order?
2. In the PDF: no entry split across pages, readable at print size, no dark backgrounds?
3. Should the printed header carry more (email, location)? The email is not printed to keep it out of the HTML in plain text.

Stop and wait for approval before Task 13.

---

### Task 13: Final cleanup, documentation and full verification

**Files:**
- Delete: every `_layouts/*` and `_includes/*` file no longer referenced (expected: `_layouts/{about,archive,book-review,book-shelf,distill,none,profiles}.liquid`, `_includes/{audio,citation,disqus,distill_scripts,giscus,latest_posts,news,newsletter,projects_horizontal,related_posts,selected_papers,video}.liquid`, `_includes/repository/`), `assets/webfonts/`, icon font files in `assets/fonts/` (`tabler-icons*`, `academicons*`, anything not matching our 12 woff2), unreferenced images in `assets/img/`
- Modify: `_pages/404.md`, `README.md`, `purgecss.config.js` (safelist)
- Test: `test/site/cleanup_test.rb`

- [ ] **Step 1: Write the failing tests**

```ruby
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
    assert doc.at_css('a[href="/"]')
  end
end
```

- [ ] **Step 2: Run to verify failure**

Run: `bin/check`
Expected: `CleanupTest` failures listing unused includes/layouts and icon fonts.

- [ ] **Step 3: Delete orphans and icon fonts**

Delete exactly the files the failing test names, plus:

```bash
git rm -rq assets/webfonts
cd assets/fonts && git rm -q $(git ls-files | grep -vE '^(pixelify-sans|jetbrains-mono|source-serif-4)-') ; cd ../..
for img in $(git ls-files assets/img | grep -v '^assets/img/favicon.ico$'); do
  name=$(basename "$img"); stem="${name%.*}"
  git grep -q -e "$name" -e "$stem" -- ':!assets/img' ':!docs' || echo "unreferenced: $img"
done
```

Remove each file printed as `unreferenced:` with `git rm`.

- [ ] **Step 4: 404 page, purge safelist, README**

`_pages/404.md`:

```markdown
---
layout: page
permalink: /404.html
title: not found
description: Nothing lives at this address.
sitemap: false
---
Go back to the [home page](/) or try [works](/works/), [publications](/publications/) or the [blog](/blog/).
```

`purgecss.config.js`:

```js
module.exports = {
  content: ["_site/**/*.html", "_site/**/*.js"],
  css: ["_site/assets/css/*.css"],
  output: "_site/assets/css/",
  skippedContentGlobs: ["_site/assets/**/*.html"],
  safelist: ["show", "collapsing", "open", "unloaded", "active"],
};
```

`README.md`:

```markdown
# philipphaslbauer.com

Personal site of Philipp Haslbauer. Jekyll, originally forked from [al-folio](https://github.com/alshedivat/al-folio) (MIT, see `LICENSE`) and stripped down.

## Run locally

Requires Ruby (version in `.ruby-version`) and ImageMagick.

    git submodule update --init
    bundle install
    bundle exec jekyll serve      # http://localhost:4000
    bin/check                     # build + tests + internal link check

## Content

| What | Where |
|---|---|
| Home bio and portrait | `_pages/about.md` |
| Works | `_projects/<name>.md` (`category`, `importance`, `img`, `description`) → `/works/<name>/` |
| Publications | `_bibliography/papers.bib` (`abbr`, `preview`, `html`, `pdf`, `doi`, `bibtex_show`) |
| Experiments (local demos) | `_experiments/<name>.md` with `layout: demo` |
| Experiments (generated) | `_experiments_src/public/<name>/` in the `experiments` submodule, with a `meta.json`; hide one via `experiments_exclude` in `_config.yml` |
| Blog | `_posts/`, plus Substack RSS (`external_sources` in `_config.yml`, cached in `_data/rss_cache/`) |
| CV | `_data/cv.yml` → `/cv/` (print it for a PDF) |
| Contact links | `_data/socials.yml` |

### Featuring items on the home page

Front matter on a work or experiment: `featured: true`, optional `featured_order: 1` and `featured_meta: "2024 · Lucerne"`.
BibTeX entry: `featured={true}`, optional `featured_order={2}`, `featured_title={Short title}`, `featured_description={One line.}`.

## Design

Tokens (colors, type scale, spacing) live in `_sass/_tokens.scss`; fonts are self-hosted in `assets/fonts/`. Dark only.

## Deploy

Pushing to `main` runs `.github/workflows/deploy.yml`: build, tests, CSS purge, publish to GitHub Pages.
```

- [ ] **Step 5: Full verification**

Run: `bin/check`
Expected: all tests pass, html-proofer `0 failures`.

Run a production build with purge, then serve the purged output statically:

```bash
JEKYLL_ENV=production bundle exec jekyll build --quiet
npx --yes purgecss -c purgecss.config.js
python3 -m http.server 4002 -d _site &
```

With the Playwright MCP against `http://localhost:4002`, for every page in `PagesTest::EXPECTED`:
- read console messages: zero errors;
- at 390×844 evaluate `document.documentElement.scrollWidth <= window.innerWidth`: must be `true` (Review Focus 2);
- on `/` at 390px, open the menu button and confirm the nav expands (purge safelist works).

Record results in `LOG.md`, then stop the server.

- [ ] **Step 6: Commit**

```bash
git add -A
git status --short   # confirm only intended files; Gemfile.lock and _data/rss_cache/substack.xml may change from builds
git commit -m "Remove orphaned templates and icon fonts; document the site"
```

- [ ] **Step 7: Hand-off**

Report to Philipp: summary of changes, the DOI question from Task 10, CI note (first CI run on Ruby 4.0.5 happens when a PR is opened). Ask whether to push `redesign` and open a pull request (outward-facing: needs his OK). Merge to `main` only after he approves the PR preview and CI is green.
