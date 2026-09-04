// User-owned dual-output facade. Posts import this file only; the pinned blog
// engine, Rin renderer, Fletcher, and HTML details stay behind this API.
#import "/site.typ": site
#import "/vendor/typst-blog-core/typst/core/shared.typ": calver, export-target
#import "/typst/core/article.typ": article as web-article, env
#import "/typst/core/home.typ": home
#import "/vendor/typst-blog-core/typst/components/embeds.typ": raw_html as core-raw-html
#import "/vendor/rin-template/template/0.3.0/template.typ": (
  conf as rin-conf,
  definition as rin-definition,
  theorem as rin-theorem,
  lemma as rin-lemma,
  proof as rin-proof,
  diagram as rin-diagram,
  node,
  edge,
  with-rin-rules,
  typsidian,
  normal_font,
  code_font,
  math_font,
)

// The core alert implementation predates the site's locale API and hard-codes
// Japanese headings. Keep its HTML contract while localizing the labels here.
#let _alert(kind, title, icon, body) = context {
  if export-target() == "paged" {
    return icon + " " + title + ": " + body
  }
  html.div(class: "markdown-alert markdown-alert-" + kind, {
    html.p(class: "markdown-alert-title", {
      html.span(class: "markdown-alert-icon", icon)
      title
    })
    html.div(class: "markdown-alert-content", body)
  })
}

#let note(body) = _alert("note", "Note", "i", body)
#let tip(body) = _alert("tip", "Tip", "+", body)
#let important(body) = _alert("important", "Important", "!", body)
#let warning(body) = _alert("warning", "Warning", "⚠", body)
#let caution(body) = _alert("caution", "Caution", "!!", body)

#let raw_html(content) = core-raw-html(content)

// Localized wrapper around the upstream embed helper. The URL parsing and
// output shape stay compatible with the core renderer.
#let youtube(url-or-id, start: none) = context {
  let m = url-or-id.match(regex("(?:v=|youtu\\.be/|embed/)([a-zA-Z0-9_-]{11})"))
  let clean-id = if m != none {
    m.captures.at(0)
  } else {
    url-or-id.split("?").at(0).split("&").at(0)
  }
  let query-params = ()
  if start != none {
    query-params.push("start=" + str(start))
  }
  let query-string = if query-params.len() > 0 { "?" + query-params.join("&") } else { "" }
  let embed-url = "https://www.youtube.com/embed/" + clean-id + query-string
  if export-target() == "paged" {
    return [#align(center)[#rect(inset: 10pt, stroke: luma(150), radius: 4pt)[YouTube: #link("https://youtu.be/" + clean-id)]]]
  }
  html.div(class: "video-wrapper", {
    html.elem("iframe", attrs: (
      src: embed-url,
      title: "YouTube player",
      frameborder: "0",
      allow: "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share",
      allowfullscreen: "",
    ))
  })
}

#let _assert-slug(slug) = {
  assert(type(slug) == str and slug.match(regex("^[a-z0-9]+(?:-[a-z0-9]+)*$")) != none,
    message: "slug must match ^[a-z0-9]+(?:-[a-z0-9]+)*$")
}

#let _assert-text(value, name) = {
  assert(type(value) == str and value.trim() != "", message: name + " is required")
}

#let _pdf-date(value) = if type(value) == dictionary {
  datetime(
    year: value.year,
    month: value.month,
    day: value.day,
  )
} else {
  value
}

#let _pdf-date-label(value) = if type(value) == datetime {
  value.display("[year]-[month padding:zero]-[day padding:zero]")
} else {
  value
}

// The pinned Rin package intentionally keeps `conf(...)` as its legacy API.
// This small adapter uses the same Typsidian/font/equation settings while
// omitting the course separator when course is absent.
#let _paged-post(title, course, author, date, body) = typsidian(
  title: title,
  author: author,
  course: if course == none { "" } else { course },
  text-args: (
    main: (font: normal_font),
    mono: (font: code_font),
    headings: (font: normal_font),
    math: (font: math_font),
  ),
)[
  #show math.equation.where(block: true): eq => {
    block(width: 100%, inset: 0pt, align(center, eq))
  }
  #show math.equation: set block(breakable: true)
  #pad(
    top: 4pt,
    align(center)[
      #block(text(size: 2em, weight: "semibold")[
        #if course == none { title } else { [#course -- #title] }
      ])
      #text(fill: rgb("#6a6a6a"), size: 1.2em)[#h(0.5em) #author #h(1em) #_pdf-date-label(date)]
      #line(length: 100%, stroke: 0.1em + black)
      #v(1em)
    ],
  )
  #with-rin-rules(body)
]

#let _block-wrapper(renderer, localized-label, topic: none, label: none, body) = renderer(
  topic: topic,
  label: if label == none { localized-label } else { label },
  body,
)

// English labels are the blog defaults, while label remains an escape hatch
// for documents that intentionally use a different language.
#let definition(topic: none, label: none, body) = _block-wrapper(rin-definition, [Definition], topic: topic, label: label, body)
#let theorem(topic: none, label: none, body) = _block-wrapper(rin-theorem, [Theorem], topic: topic, label: label, body)
#let lemma(topic: none, label: none, body) = _block-wrapper(rin-lemma, [Lemma], topic: topic, label: label, body)
#let proof(label: [Proof.], body) = rin-proof(label: label, body)
#let diagram(..args, alt: none, caption: none) = rin-diagram(..args, alt: alt, caption: caption)
#let conf = rin-conf

// Canonical authoring API. The enriched metadata keeps the original PDF title
// and course available to the PDF publisher while the core's `title` field is
// the combined web/feed/search/SEO title.
#let post(
  slug: none,
  title: none,
  create: none,
  description: none,
  course: none,
  author: none,
  update: none,
  tags: (),
  abstract: none,
  og-image: none,
  draft: true,
  body,
) = context {
  _assert-slug(slug)
  _assert-text(title, "title")
  _assert-text(description, "description")
  assert(create != none, message: "create is required")
  assert(course == none or (type(course) == str and course.trim() != ""), message: "course must be none or a non-empty string")
  assert(author == none or (type(author) == str and author.trim() != ""), message: "author must be none or a non-empty string")
  assert(type(tags) == array, message: "tags must be an array")
  assert(type(draft) == bool, message: "draft must be true or false")

  let effective-author = if author == none { site.author.name } else { author }
  let web-title = if course == none { title } else { course + " · " + title }
  let meta = (
    slug: slug,
    title: web-title,
    pdf-title: title,
    course: course,
    authors: (effective-author,),
    create: create,
    update: update,
    tags: tags,
    description: description,
    abstract: abstract,
    og-image: og-image,
    draft: draft,
  )

  let render = if target() == "html" {
    web-article(
      slug: slug,
      title: web-title,
      authors: (effective-author,),
      create: create,
      update: update,
      tags: tags,
      description: description,
      abstract: abstract,
      og-image: og-image,
      draft: draft,
      with-rin-rules(body),
    )
  } else {
    set document(title: title, author: (effective-author,))
    _paged-post(
      title,
      course,
      effective-author,
      _pdf-date(create),
      body,
    )
  }

  [#metadata(meta) <post-meta>] + render
}
