# Rin's Typst Blog

This repository is a personal study blog built with Typst. Write each post
once and the build produces both a semantic HTML article and a paged PDF. The
HTML site, RSS feed, sitemap, tag pages, search index, and PDF links are all
generated from the same source.

Live site: <https://Ayupyon.github.io/typst-blog/>

Source repository: <https://github.com/Ayupyon/typst-blog>

This README follows the structure of the upstream
[Typst Blog Template](https://github.com/minimarimo3/typst-blog-template), with
the Rin dual-output and English authoring details added for this repository.

## Features

- Write posts and site settings entirely in Typst.
- Generate semantic HTML and a matching paged PDF from one post source.
- Set title, course, author, created date, updated date, description, tags,
  abstract, social image, and draft status per post.
- Render Definition, Theorem, Lemma, and Proof blocks with shared numbering and
  same-post references in both targets.
- Render Note, Tip, Important, Warning, and Caution callouts with semantic HTML
  classes and matching PDF output.
- Wrap Fletcher 0.5.8 diagrams with required alternative text and an optional
  caption.
- Generate the home page, post pages, tag pages, tag index, RSS, sitemap, and a
  Pagefind search index.
- Publish the contents of `public/` to GitHub Pages with the included workflow.
- Keep the blog engine and Rin template in pinned Git submodules.
- Customize themes, fonts, images, extra CSS, and the Project Pages base path.

## Requirements

| Tool | Version |
| --- | --- |
| Git | Any recent version |
| Typst | 0.15.1 (the CI version) |
| Python | 3.10 or later |
| uv | 0.12.9 (the CI version) |
| Node.js | 20 or later |

Node.js runs Pagefind, which builds the search index. The pinned Rin template
fetches Fletcher 0.5.8 through Typst's package system; no separate global
Fletcher installation is required.

## Quick Start

### 1. Create your repository and clone it

Create a repository from this template or fork this one, then clone it with its
submodules:

```sh
git clone --recurse-submodules https://github.com/USER/REPO.git
cd REPO
```

If the repository has already been cloned and
`vendor/typst-blog-core` or `vendor/rin-template` is empty, initialize the
submodules:

```sh
git submodule update --init --recursive
```

### 2. Edit the site settings

Install the required versions listed above and install the reproducible Python
dependencies from the committed lockfile:

```sh
uv sync --frozen
```

The commands below use `uv run`, so they run against the environment managed by
the project rather than relying on packages installed globally.

Open `site.typ` and replace the example values with the settings for your blog.
These are the main options:

| Key | Description |
| --- | --- |
| `title` | Blog name |
| `description` | Blog description |
| `base_url` | Public URL, without a trailing `/` |
| `github_repo` | GitHub repository URL |
| `language` | Primary HTML language, such as `"en"` or `"zh-CN"` |
| `theme` | A file name under `static/themes/` |
| `posts_dir` | Where posts live; this repository uses `"posts"` |
| `update_policy` | `"git"` for commit dates or `"manual"` for post metadata |
| `author.name` | Author name |
| `author.bio` | Author profile text |
| `author.socials` | Social links |

For a GitHub Project Pages site, `base_url` normally looks like this:

```typst
base_url: "https://USER.github.io/REPO"
```

Use the custom domain URL instead when deploying to a custom domain.

### 3. Create a post

Use the helper command to create a draft post with a valid slug:

```sh
uv run python command.py new my-first-post \
  --title "My First Post" \
  --description "A short description of the post." \
  --tag Typst
```

This creates `posts/my-first-post/index.typ`. Repeat `--tag` for more tags, use
`--publish` to create a published post, or pass `--date YYYY-MM-DD` for an
explicit creation date.

### 4. Preview locally

Start the local preview server:

```sh
uv run python command.py preview
```

After the first build, open the URL printed by the command (normally
`http://localhost:8000`).

### 5. Publish

Push the `main` branch when the post is ready; the GitHub Actions workflow
builds and deploys `public/` to Pages.

## Writing Posts

One post is one directory. The `index.typ` file contains the metadata header
and body, while images and bibliography files can live beside it. This
repository keeps posts under `posts/`; the standalone `example-post/` is a
complete syntax fixture and is compiled by CI.

### Create a new post

Use the helper command to create a draft post with a valid slug:

```sh
uv run python command.py new my-first-post \
  --title "My First Post" \
  --description "A short description of the post." \
  --tag Typst
```

The created date defaults to the day the command runs and the post starts as a
draft. Repeat `--tag` for multiple tags, add `--publish` to start published, or
pass `--date YYYY-MM-DD` for an explicit creation date. A directory with an
existing slug or reserved URL is rejected.

### Post file format

Posts import only the root facade:

```typst
#import "/template.typ": post, calver, theorem, proof

#show: post.with(
  slug: "my-first-post",
  title: "My First Post",
  course: "Typst",
  create: calver(2026, 7, 19),
  description: "A short description of the post.",
  tags: ("Typst",),
  draft: true,
)

= Introduction

Write your content here.

#theorem(topic: [A sample theorem])[
  The body can contain ordinary Typst content.

  #proof[The proof uses the same source in HTML and PDF.]
] <sample-theorem>

See @sample-theorem.
```

The `post` show rule registers metadata and renders all following content with
the selected target layout.

### Post metadata

| Key | Description |
| --- | --- |
| `slug` | Lowercase ASCII kebab-case URL, such as `my-first-post` |
| `title` | Post title and PDF document title |
| `course` | Optional course/category prefix for web titles |
| `author` | Optional per-post author override |
| `create` | Required creation date, normally `calver(...)` |
| `update` | Optional manual updated date |
| `description` | Required short description for cards and search |
| `tags` | Array of tag names |
| `abstract` | Optional longer summary for metadata |
| `og-image` | Optional social preview image |
| `draft` | `true` by default; set to `false` to publish |

When `course` is present, the web title, H1, SEO metadata, RSS entry, home card,
tag page, and search index use `Course · Title`. Without a course, they use the
title alone. The PDF keeps the unprefixed `title` as its document metadata and
uses the same author fallback as the web output.

### Supported syntax

The root facade exposes standard Typst content plus:

- `definition`, `theorem`, `lemma`, and `proof` blocks;
- `note`, `tip`, `important`, `warning`, and `caution` callouts;
- `diagram`, `node`, and `edge` for accessible Fletcher diagrams;
- environment tables, raw HTML, YouTube embeds, citations, bibliography,
  figures, images, tables, lists, footnotes, equations, links, and code.

The visible block labels are English by default: **Definition**, **Theorem**,
**Lemma**, **Proof**, **Note**, **Tip**, **Important**, **Warning**, and
**Caution**. Each theorem-like block resets its numbering at a level-one
heading and preserves references in both output targets.

The site's navigation and metadata strings follow `site.language`; the current
site is configured for `zh-CN`, while these authoring block labels are
intentionally English.

Every `diagram` call must provide non-empty `alt` text:

```typst
#diagram(
  node((0, 0), [A]),
  node((1, 0), [B]),
  edge((0, 0), (1, 0), "->"),
  alt: "An arrow from A to B",
  caption: [A simple morphism.],
)
```

The diagram is an inline SVG in HTML and a figure in the PDF. Put important
relationships in the alternative text, caption, or nearby prose because SVG
paths are not searchable text.

### Drafts and publishing

Toggle publication with `draft`:

- In `preview`, drafts are shown and marked as drafts. They receive `noindex`
  and are excluded from search results.
- In a production `build`, drafts are excluded from post pages, lists, tag
  pages, RSS, sitemap, Pagefind, and the deployed PDF tree.
- Every published post receives `public/<slug>/post.pdf` and a relative PDF
  link beside its article metadata.

### How the updated date works

With `update_policy: "git"`, the latest commit touching a post directory is
used as its updated date. With `update_policy: "manual"`, the `update` value in
the post is used. If Git history is unavailable, the build warns and falls
back to an explicitly supplied `update` value.

### Keeping posts under `posts/`

Set `posts_dir: "posts"` in `site.typ` to keep post directories below
`posts/`. The same setting controls where `command.py new` creates posts and
where the builder looks for them. Set it to `"."` only when posts should live
at the repository root.

## Previewing Locally

Run the preview server with:

```sh
uv run python command.py preview
```

Saving Typst, CSS, JavaScript, image, or bibliography files triggers a rebuild.
Press `Ctrl+C` to stop the server. Preview switches the base path to `/` for
the local server while canonical URLs, RSS, and the sitemap continue to use
the configured `base_url`.

To build the search index during preview, run this in another terminal:

```sh
npx -y pagefind@1.5.2 --site public
```

For the complete production pipeline, use:

```sh
uv run python scripts/build_site.py
```

This validates draft-inclusive HTML, builds production HTML, compiles and
publishes only non-draft PDFs, injects relative PDF links, builds Pagefind,
checks generated output, and verifies local links. Other useful commands are:

```sh
uv run python command.py build
uv run python scripts/build_pdfs.py --mode validation
uv run python scripts/verify_outputs.py --production
uv run python scripts/check_links.py
uv run pytest
```

## Publish with GitHub Pages

The included workflow is ready for GitHub Pages. For a new repository, perform
this one-time setup:

1. Set `base_url` and the other site settings in `site.typ`.
2. Open **Settings → Pages** on GitHub.
3. Set **Source** under **Build and deployment** to **GitHub Actions**.
4. Push the `main` branch.

Pull requests run the complete validation job without deploying. Pushes to
`main` and manual workflow runs build, upload, and deploy the contents of
`public/`.

### Using a custom domain

Add the domain to `static/CNAME` (or `CNAME` at the repository root) and set
`base_url` in `site.typ` to the same domain.

## Changing the Look

### Switch themes

Set `theme` in `site.typ` to a CSS file under `static/themes/`. This repository
ships `rin-dark.css`, which layers the core dark theme with the Rin block and
diagram styles.

```typst
theme: "rin-dark"
```

### Create your own theme

Add `static/themes/my-theme.css` and set:

```typst
theme: "my-theme"
```

The file can import the core light or dark theme and override the custom
properties and component selectors it needs.

### Fonts, images, and extra CSS

Files under `static/` are copied to `public/` as-is. The current configuration
uses Noto Serif CJK fallbacks for Chinese-capable PDF output and a web stack
that can use Noto Serif SC when Google Fonts is available. Always keep a local
system fallback in the stack. Fira Code is used for code when installed, with a
monospace fallback.

## File Layout

Files you usually edit:

| Path | Description |
| --- | --- |
| `site.typ` | Site name, public URL, locale, theme, fonts, author, and services |
| `AGENTS.md` | Development notes and invariants for agents and contributors |
| `template.typ` | Public post facade and dual-target renderers |
| `posts/<slug>/index.typ` | Post metadata and body |
| `example-post/index.typ` | Complete English syntax fixture |
| `static/` | Themes, CSS, JavaScript, images, and other static assets |
| `scripts/` | HTML/PDF/Pagefind build and verification tools |
| `.github/workflows/deploy.yml` | CI validation and Pages deployment |

Files you normally do not edit directly:

| Path | Description |
| --- | --- |
| `vendor/typst-blog-core` | Pinned blog engine; update it as a submodule |
| `vendor/rin-template` | Pinned Rin template, currently `0.3.0` |
| `typst/core/` | User-owned compatibility copies for the `zh-CN` Typst language code |
| `typst/generated/posts.typ` | Post list data regenerated by the builder |
| `public/` | Generated deployment output |

## Updating the Blog Engine or Rin

Both engines are recorded as Git submodules. Update one dependency at a time on
a dedicated branch, use a release tag or exact commit, and run the complete
local gates before pushing.

To rehearse a blog-core update:

```sh
cd vendor/typst-blog-core
git fetch --tags
git tag --sort=-version:refname
git checkout vYYYY.MM.DD
cd ../..
uv run python scripts/build_site.py
uv run pytest
git add vendor/typst-blog-core
git commit -m "Update blog core"
```

To select a Rin release, use the same process in `vendor/rin-template` and keep
the root facade compatible with the pinned `0.3.0` API. `git add` records the
submodule commit; it does not copy the vendored contents into this repository.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| A submodule is empty or missing | Run `git submodule update --init --recursive` |
| `uv sync --frozen` reports a lock mismatch | Use the committed `uv.lock`; regenerate it only when dependencies intentionally change |
| Typst reports an unsupported version | Install Typst 0.15.1, the version used by CI |
| A post is absent from production | Set `draft: false` and check that its directory name matches its slug |
| Public URLs contain the wrong path | Set `base_url` without a trailing `/` |
| Search is empty | Run `npx -y pagefind@1.5.2 --site public` after a production build |
| A diagram fails to compile | Supply non-empty `alt` text to `diagram(...)` |
| Pages cannot configure the site | Enable **Settings → Pages → GitHub Actions** once for the repository |

## About the Misskey Icon

Misskey sharing and the Misskey sidebar icon are disabled in this repository's
`site.typ`. If you enable them, check the upstream icon license and set the
corresponding `share.misskey` and social-link values explicitly.

## License

The code in this repository is provided under the MIT License. See
[LICENSE](LICENSE) for the full text.
