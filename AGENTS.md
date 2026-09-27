# AGENTS.md

## What this project is

This is the source for a personal blog ("Thoughtfull Systems"), a static site
built with [Hugo](https://gohugo.io/) (extended) using the vendored
[Congo](https://github.com/jpanther/congo) theme. It is deployed to GitHub Pages
via `.github/workflows/hugo.yaml` on every push to `main`.

## Golden rule: infrastructure only, never content

The agent's job is to manage the **infrastructure** of this site. The agent
**must not write, rewrite, edit, or generate any of the blog's content** — the
words are the author's. This is a hard boundary, not a preference.

**Content (do NOT create, edit, or ghostwrite — this is off-limits):**
- Everything under `content/` — the notes, topics, and posts, including their
  front matter's human-authored fields (title, summary, body prose, tags chosen
  for meaning).
- Author-voice site copy: the site description, author bio, and similar prose in
  `config/_default/languages.en.toml` and `config/_default/params.toml`.

If asked to write, draft, expand, summarize, or "improve the wording" of a post,
decline and hand it back to the author. You may point out a broken link, a
malformed date, or a Hugo build error in a content file, but the fix to the
prose itself is the author's to make.

**Infrastructure (this is your remit):**
- Build & tooling: `devenv.nix`, `devenv.lock`, `.envrc`, Hugo version pins.
- Theme: upgrading/patching the vendored theme under `themes/`, and wiring it
  in `config/_default/`.
- Site configuration and Hugo mechanics in `config/_default/` (output formats,
  markup, menus, permalinks, taxonomies, module settings) — the plumbing, not
  the prose.
- CI/CD & deployment: `.github/workflows/`.
- Repo hygiene: `.gitignore`, layout/asset scaffolding in `layouts/`, `assets/`,
  `static/`.

When a change touches both (e.g. a config file holds both a Hugo setting and the
author's bio), change only the infrastructure part and leave the prose untouched.

## Working in this repo

- **Dev shell:** `devenv shell` provides Hugo (extended), Dart Sass, and git.
- **Preview:** `serve` (alias for `hugo server --buildDrafts --buildFuture`),
  served at http://localhost:1313/.
- **Production build:** `build` (alias for `hugo --gc --minify`) — mirrors CI.
- Always confirm a clean `hugo --gc` build (no `WARN`/`ERROR`, no deprecation
  notices) before considering an infrastructure change done.
- The theme is **vendored**, not a submodule or Hugo module. Theme upgrades mean
  replacing the directory under `themes/` and updating `theme:` in
  `config/_default/config.yaml`.

## Prose linting (Vale)

- `content/**/*.md` is linted with [Vale](https://vale.sh/) using proselint,
  write-good, and Vale's built-in spelling. Config is in `.vale.ini`; styles and
  the project vocabulary are vendored under `.vale/`.
- A devenv-managed **pre-commit hook blocks the commit on any Vale finding**
  (`MinAlertLevel = suggestion`). Run `lint` to check all content on demand.
- The hook flags prose; **the fix is the author's** (reword, or accept the
  finding). Infrastructure-side, you may: add a legitimate term to
  `.vale/styles/config/vocabularies/Blog/accept.txt`, disable/adjust a rule in
  `.vale.ini`, or run `vale sync` after changing `Packages`. Do not reword the
  author's sentences to satisfy the linter.

## Git

- Commit or push only when the author asks.
- Do not add co-authorship trailers to commits, and do not add co-authorship or
  "generated with" attribution to pull requests. The author is the sole author.
