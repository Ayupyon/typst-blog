# Development Notes for Agents

## Scope

These notes apply to the whole repository. The repository is a Typst blog that
publishes one source post as both semantic HTML and a paged PDF. Keep changes
reproducible from a clean clone; never rely on a developer-specific absolute
path or an uncommitted local file.

## Repository map

- `site.typ` contains the site metadata, locale, base URL, theme, fonts, author,
  and optional services.
- `template.typ` is the public authoring facade. Posts should import this file,
  not blog-core, Rin internals, Fletcher, or HTML implementation details.
- `posts/<slug>/index.typ` contains normal posts. `example-post/` is the
  complete English syntax fixture compiled by CI but is outside `posts_dir`.
- `typst/core/` contains user-owned copies of the core page entrypoints. They
  preserve the `zh-CN` HTML locale while using the ISO `zh` code required by
  Typst text shaping. Do not replace them with edits to the core submodule.
- `vendor/typst-blog-core` and `vendor/rin-template` are pinned Git
  submodules. The Rin submodule is pinned to release `0.3.0`.
- `scripts/` owns PDF publication, HTML/PDF verification, Pagefind execution,
  and local-link checks. `public/` is generated and ignored by Git.
- `.github/workflows/deploy.yml` runs the validation gate for pull requests and
  deploys `public/` to GitHub Pages from `main`.

## Authoring contract

Every post must use a lowercase ASCII kebab-case slug and keep the directory
name equal to that slug. The `post` facade requires `slug`, `title`, `create`,
and `description`; `draft` defaults to `true`. `command.py new` accepts an
optional `--course` value and writes it into the generated metadata. A `course`
prefixes web/feed/SEO titles as `Course · Title`, while the PDF document title
remains `title`.

The facade's default visible labels are English: Definition, Theorem, Lemma,
Proof, Note, Tip, Important, Warning, and Caution. Preserve these defaults when
adding fixtures unless a test explicitly covers a label override. Fletcher
diagrams must use the facade's `diagram(...)` wrapper and provide non-empty
alternative text. Add a label after a diagram when prose needs to refer to it
(`#diagram(...) <diagram-label>` followed by `@diagram-label`). Captions display
independent Diagram numbering in both outputs. Keep important diagram
relationships in `alt`, captions, or nearby prose so they remain available to
screen readers and search.

Alert helpers keep Note, Tip, Important, Warning, and Caution unnumbered. They
render semantic alert cards in HTML and breakable colored boxes with an icon
and label title row in PDF; preserve the body as native Typst content.

Native HTML MathML must keep Typst's generated display mode. The stylesheet may
add horizontal overflow to display equations, but must not force them to
`display: block`, which makes Chromium stack equation children vertically.
Paragraphs containing inline equations should use start alignment rather than
justification so CJK spacing remains readable.

## Reproducible commands

Install the committed Python environment without changing dependency versions:

```sh
uv sync --frozen
```

The normal validation commands are:

```sh
uv run python scripts/build_site.py
uv run pytest
python3 -m py_compile command.py scripts/*.py tests/*.py
```

`build_site.py` validates draft-inclusive HTML, builds production HTML,
compiles published PDFs, injects relative PDF links, builds Pagefind, and runs
the output/link checks. Use `--skip-pagefind` only for an offline intermediate
build; the production gate must include Pagefind.

For the standalone Rin gate, run the verifier inside the Rin submodule:

```sh
python3 vendor/rin-template/tests/verify.py
```

When a command needs network access (for example, the first Pagefind or Typst
package download), use the approved unrestricted execution path. Do not work
around a failed dependency download by changing the lockfile or pin.

## Testing expectations

Before committing a renderer or fixture change, verify both targets. At a
minimum, inspect the generated HTML for semantic classes, stable anchors,
accessible diagram descriptions, metadata, and the relative `post.pdf` link;
inspect the PDF for readability, title/author metadata, numbering, and English
labels. Drafts must compile during validation but must not appear in production
HTML, PDF, RSS, sitemap, or Pagefind output.

Tests that exercise draft posts may temporarily build an inclusive `public/`
tree. Always restore the production tree before finishing and check `git status`
for generated or temporary files.

## Submodules and generated files

Do not edit files inside either vendored submodule as part of a blog change.
Update a submodule only on a dedicated branch, selecting an exact release tag
or commit, then run the complete local and CI gates. A submodule update records
only its commit pointer in the blog repository.

Do not hand-edit `typst/generated/posts.typ` or anything under `public/`.
Builders regenerate them. Keep temporary PDFs outside the repository (for
example under `/tmp`) so they cannot be accidentally committed.

## Documentation and CI

The root `README.md` follows the upstream template's section order and is the
primary English guide. Keep examples generic and reproducible; never document
machine-specific virtual-environment paths. If a workflow or public API changes,
update the README and this file in the same change.

The Pages workflow expects Typst 0.15.1, uv 0.12.9, Node.js 20+, Python 3.10+,
Noto CJK fonts, and Fira Code. It checks the recursive submodule state before
building. Pull-request runs must not deploy; main-branch runs must configure,
upload, and deploy the Pages artifact.

## Change discipline

Prefer small, reviewable commits. Preserve unrelated user work, use
`apply_patch` for source edits, and avoid destructive Git or filesystem
commands. Before handoff, run `git diff --check`, the relevant tests, and
`git status --short --branch`.
