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

Front matter on a work or experiment: `featured: true`, optional `featured_order: 1`. The mono line under a work's title and on its cards comes from `meta: "2024–2026 · Lucerne"` (falls back to `year`).
BibTeX entry: `featured={true}`, optional `featured_order={2}`, `featured_title={Short title}`, `featured_description={One line.}`.

## Design

Tokens (colors, type scale, spacing) live in `_sass/_tokens.scss`; fonts are self-hosted in `assets/fonts/`. Dark only.

## Deploy

Pushing to `main` runs `.github/workflows/deploy.yml`: build, tests, CSS purge, publish to GitHub Pages.
