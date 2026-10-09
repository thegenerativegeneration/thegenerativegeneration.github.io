# Site cleanup and redesign — design

Date: 2026-10-09 · Branch: `redesign` · Status: awaiting review

## Goal

Turn the al-folio fork into a lean personal site that presents Philipp Haslbauer as an
artist-researcher, and fix the visible defects of the live site. The current visual
identity (dark, pixel display type, mint and pink) stays, refined rather than replaced.

Audience, in order: curators and the art world, then academic peers and hiring committees.

## Decisions

| Topic | Decision |
|---|---|
| Technical approach | Strip al-folio down in place (no rewrite, no new generator) |
| Sections | Home, Works, Publications, Experiments, Blog, CV |
| Homepage | Portrait + name + bio + text links, then a grid of featured cards (layout "A") |
| Featured items | Front-matter flag `featured: true` plus `featured_order` |
| Theme | Dark only; all light/dark toggle code removed |
| Typography | Pixelify Sans (display), JetBrains Mono (structure), Source Serif 4 (body) |
| Palette | "B3 Deep green night" (tokens below) |
| Substack | Keep the RSS import |
| CV | HTML page from `_data/cv.yml` with a print stylesheet; no hand-made PDF |
| Socials | Email, Instagram, LinkedIn, Google Scholar (plus a CV link), as text links |
| URLs | May change freely; no redirects required |
| Blog archives | Drop tag/year archive pages |
| `Gemfile.lock` | Track it; remove from `.gitignore` |

## Defects to fix (observed on the live site, 2026-10-09)

1. `ReferenceError: determineComputedTheme is not defined` on every page
   (`common.js`, `no_defer.js` call a function from the removed theme toggle).
2. Fixed footer overlaps content while scrolling.
3. Works page renders empty categories ("in preparation", "past"); category
   labels are right-aligned and detached from their cards.
4. Morse Chatbot experiment card has no image or description: its `meta.json` in the
   `experiments` repo has a trailing comma, and `ExperimentsGenerator#read_meta`
   swallows the parse error with a warning.
5. Mobile home: name renders below the photo and the icon block; side gutters too wide.
6. Inconsistent type: pixel font on all heading levels, oversized social icons.

## Scope: remove

- Upstream docs and tooling: al-folio `README.md`, `CUSTOMIZE.md`, `FAQ.md`,
  `CONTRIBUTING.md`, `INSTALL.md`, `.all-contributorsrc`, `readme_preview/`,
  `lighthouse_results/`, `Dockerfile`, `docker-compose*.yml`, `.devcontainer/`,
  `.dockerignore`, `.tweet-cache/`, and `bin/` scripts no longer used by CI.
- Workflows: all except `deploy.yml` and `broken-links-site.yml`; also
  `schedule-posts.txt`.
- Demo assets: `assets/video/*` (al-folio tutorial, Pexels clip), `assets/audio/*`,
  `assets/plotly/`, `assets/jupyter/`, `assets/pdf/example_pdf.pdf`,
  `assets/js/distillpub/`, `assets/img/template_error.png` if unreferenced, and any
  other asset with no reference in the built site.
- Layouts: `distill`, `bib`, `book-review`, `book-shelf`, `archive`, `profiles`,
  `about` (the CV variant `about_cv` is replaced by the new home layout).
- Includes: giscus, disqus, newsletter, news, latest_posts, repository/, audio, video,
  distill_scripts, selected_papers (replaced by featured cards), projects_horizontal.
  `figure.liquid` stays: it renders responsive images through jekyll-imagemagick.
- JS: chartjs, echarts, leaflet, mermaid, plotly, vega, pseudocode, diff2html,
  typograms, wechat, jupyter_new_tab, search and search-setup, newsletter,
  shortcut-key, progress-bar, theme.js, masonry (replaced by CSS grid),
  mathjax-setup.
- CSS: jupyter styles, unused pygments theme, `_distill.scss`, `_typograms.scss`,
  `_tabs.scss`, icon fonts (Font Awesome, Academicons, Tabler, scholar-icons) once no
  template references them.
- Plugins/gems: jekyll-jupyter-notebook, jekyll-twitter-plugin, jekyll-tabs,
  jekyll-get-json, jekyll-archives-v2, citation-count plugins
  (`google-scholar-citations.rb`, `inspirehep-citations.rb`), `download-3rd-party.rb`
  (a no-op with `download: false`), and their `_config.yml` blocks. The
  `third_party_libraries` block stays, since templates read CDN URLs and integrity
  hashes from it, but is pruned to the libraries still loaded.
- Pages: `_pages/teaching.md`, `_pages/dropdown.md`. `_pages/cv.md` is rewritten.
- Config: every unused `enable_*` flag and third-party block (analytics, giscus,
  disqus, newsletter, repo stats, trophies, search). Target: `_config.yml` under
  ~200 lines (currently 647).

## Scope: keep

jekyll-scholar, `experiments_generator.rb`, `external-posts.rb` (Substack),
jekyll-sitemap, jekyll-feed, jekyll-email-protect, jekyll-imagemagick (responsive
images), jekyll-toc, jekyll-minifier, Rouge, Bootstrap/MDB (nav collapse, grid
utilities), Google site verification, the `experiments` submodule.

## Visual system

### Tokens

All tokens live in one partial (`_sass/_tokens.scss`) as CSS custom properties.

| Token | Value | Use |
|---|---|---|
| `--bg` | `#07110b` | page background |
| `--text` | `#cfe6d2` | running text (14.5:1 on bg) |
| `--head` | `#c6f7bd` | name, titles, nav, card titles |
| `--accent` | `#ff7ac2` | section labels, badges, active nav, in-text links (8.1:1) |
| `--muted` | `#86a08c` | metadata (6.8:1) |
| `--rule` | `#26402e` | dividers, chip borders, link underlines |
| `--glow` | `0 0 8px rgba(198,247,189,.35)` | name and page titles only |

Badge text uses `--bg` on `--accent`. All pairs pass WCAG AA; ratios computed with the
WCAG 2.x relative-luminance formula.

### Type

- Display (name, page titles, nav): Pixelify Sans 500.
- Structure (section labels in uppercase with 0.14em tracking, item titles, metadata,
  badges, chips, buttons): JetBrains Mono 400/500.
- Running text: Source Serif 4 400 (optical sizes).
- All three are OFL; self-host as woff2 subsets in `assets/fonts/` with
  `font-display: swap`. Remove the Google Fonts request, Roboto and VT323.
- One modular scale (ratio ~1.25) defined as tokens; no per-component ad-hoc sizes.

### Layout

- Content max-width ~1100px (replaces `max_width: 80%`); reading width ~68ch for
  prose (post bodies, work pages).
- Spacing scale on a 4px base.
- Side gutter 20px under 576px.

### Components

- **Nav:** name (display font) left on inner pages, links right, active link in
  accent. Bootstrap collapse under 768px.
- **Footer:** static (not fixed); copyright and the same text links as the home page.
- **Card:** 4:3 image, accent type badge (`work` / `paper` / `experiment`), mono title,
  mono metadata line, one-line serif description. Used on Home, Works, Experiments.
- **Row:** thumbnail left, mono title, serif authors/venue or description, outlined
  mono chips for links. Used on Publications and Blog.
- **Text links:** in-text links in accent with `--rule` underline; nav and card titles
  in `--head`.

## Pages

- **Home `/`:** portrait (square) beside name, one-paragraph bio and text links
  (email · instagram · linkedin · scholar · cv); then "Selected" label and a card grid
  of featured items, 3/2/1 columns at desktop/tablet/phone. Featured items are
  gathered from `site.projects`, `site.experiments` and bibliography entries with
  `featured={true}`, sorted by `featured_order`. Papers link to `html`, else `doi`,
  else `pdf`. Bio text to be supplied by Philipp.
- **Works `/works/`:** card grid; categories without items are not rendered; category
  labels left-aligned above their grid.
- **Work page:** title block (display title, mono line with year, venue, place), prose
  at reading width, full-width images.
- **Experiments `/experiments/`:** card grid over local demos and generated
  experiments.
- **Experiment and demo pages:** existing behaviour kept; restyled header only.
- **Publications `/publications/`:** year labels, Row component, filter box kept and
  restyled.
- **Blog `/blog/`:** Row component; Substack items carry a `substack ↗` chip.
- **Post:** reading width, TOC above the body instead of a sidebar, dark Rouge theme.
- **CV `/cv/`:** all `cv.yml` sections as a two-column timeline (year | entry). Print
  stylesheet: white background, black text, nav/footer hidden, A4 margins, no breaks
  inside entries. A "Download PDF" button calls `window.print()`. Linked from home and
  footer, not from the main nav.
- **404:** restyled, no auto-redirect.

## Code health

- `_sass/_base.scss` (1458 lines) is split into focused partials (tokens, base,
  typography, nav/footer, card, row, cv, print) each under ~300 lines.
- `ExperimentsGenerator#read_meta` raises on invalid JSON instead of warning, so a
  broken experiment fails the build.
- Ruby version pinned in a tracked `.ruby-version`; `deploy.yml` uses
  `ruby-version-file`. Local Ruby is 4.0.5, CI 3.3.5; the baseline step decides which
  version the plugin set supports.
- `docs/`, `.superpowers/` and `.playwright-mcp/` excluded from the Jekyll build.
- New `README.md` covering: local setup, adding a work / paper / experiment,
  `featured` flags, the experiments submodule, deployment.

## Outside this repository

Fix the trailing comma in `public/morse-chatbot/meta.json` in
`thegenerativegeneration/experiments`, then bump the submodule here.

## Verification

1. **Baseline:** build the unchanged site with the pinned Ruby; save the `_site` page
   list and screenshots of all pages (1440px and 390px) as the "before" reference.
2. **Per commit:** `bundle exec jekyll build` succeeds with no new warnings.
3. **Per page group:** `html-proofer` on `_site` (internal links and images; external
   links skipped locally), zero console errors on every page in a headless browser,
   page-list diff against the baseline with every removed URL accounted for.
4. **Visual review by Philipp:** after each page group, before/after screenshots at
   desktop and 390px with explicit comparison criteria. Nothing merges to `main`
   (which deploys) without approval.
5. **Print check:** CV printed to PDF from Chrome, reviewed by Philipp.

## Record keeping

Decisions, findings (palette contrast table, the Ruby version result, the
`meta.json` bug) and before/after screenshots go to
`/Volumes/T7 Shield/Temp/website-redesign/`.

## Out of scope

Light mode; site search; comments; analytics; newsletter; redirects for changed URLs;
new content beyond the homepage bio; replacing Bootstrap; changes to the experiments
themselves beyond the `meta.json` fix.
