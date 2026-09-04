#import "/template.typ": (
  post, calver, env,
  definition, theorem, lemma, proof, diagram, node, edge,
  note, tip, important, warning, caution,
  raw_html, youtube,
)

#show: post.with(
  slug: "example-post",
  title: "Example Post: Supported Syntax",
  course: "Typst Blog",
  author: "Example Author",
  create: calver(2026, 1, 1),
  update: calver(2026, 4, 1),
  description: "An English sample covering the syntax supported by the blog facade.",
  tags: ("Typst", "Template", "Example"),
  abstract: "A regression fixture for semantic HTML, paged PDF output, references, and embeds.",
  og-image: "https://example.com/example-post.png",
  draft: false,
)

#env(
  ("Typst", "0.15.1", "HTML and PDF export"),
  ("Python", "3.10+", "build and validation scripts"),
  ("Pagefind", "1.5.2", "search index generation"),
)

= Shared semantics

This sample is intentionally written in English. One Typst source produces a
semantic HTML article and a paged PDF, so the same headings, labels, references,
and accessible descriptions must work in both targets.

Here is a forward reference to a theorem introduced later: @later-theorem.

#definition(topic: [A small group])[
  A group is a set equipped with an associative operation, an identity element,
  and an inverse for every element.
] <group-definition>

#theorem(topic: [The identity element])[
  The identity element of a group is unique.

  #proof[
    If $e$ and $e'$ are both identity elements, then
    $e = e e' = e'$.
  ]
] <identity-theorem>

#lemma[
  For every group element $a$, the inverse of the inverse is $a$:
  $(a^(-1))^(-1) = a$.
] <inverse-lemma>

The first blocks can be referenced by their labels:
@group-definition, @identity-theorem, and @inverse-lemma.

#proof(label: [Proof.])[
  This standalone proof demonstrates the explicit label parameter and ends
  with the standard square marker.
]

== Inline formatting, lists, and code

*Bold text* and _italic text_ sit next to `inline code` and a URL:
https://example.com.

#link("https://example.com/docs")[A link with display text] and a
'single-quoted phrase' and a "double-quoted phrase" exercise ordinary links
and punctuation.

* Unordered item
* Another item
  * Nested item
  * Another nested item
+ Ordered item
+ Another ordered item

/ Term: A definition list item
/ HTML export: Rendering the same Typst source as HTML

```c
#include <stdio.h>

int main(void) {
  printf("hello\\n");
  return 0;
}
```

#figure(
  ```typst
  #let greet(name) = [Hello, #name!]
  #greet("Typst")
  ```,
  caption: [A Typst code figure.],
) <code-figure>

The reference @code-figure points to the caption above.

== Quotes and mathematics

#quote(attribution: [Plato])[
  ... ἔοικα γοῦν τούτου γε σμικρῷ τινι αὐτῷ τούτῳ σοφώτερος εἶναι, ὅτι
  ἃ μὴ οἶδα οὐδὲ οἴομαι εἰδέναι.
]

#quote(attribution: [Henry Cary's literal translation, 1897])[
  ... I seem, then, in just this little thing to be wiser than this man at
  any rate, that what I do not know I do not think I know either.
]

Inline mathematics: $(v dot nabla) v < "nya"$.

Display mathematics:

$
  integral_0^1 x^2 dif x = 1 / 3
$

== References, figures, and tables <media-and-references>

This internal link points back to @media-and-references, while this one points
to an external site: #link("https://typst.app")[Typst].

The citation @typst-html-2026 documents the fixture. Two citations can appear
together: @typst-html-2026 and @template-regression-2026.

#figure(
  image("./test-image.png", alt: "A small test image containing the word Typst"),
  caption: [A local raster image with alternative text.],
) <test-image>

The image reference @test-image checks figure captions and labels.

#diagram(
  node((0, 0), [A]),
  node((1, 0), [B]),
  node((1, 1), [C]),
  edge((0, 0), (1, 0), "->"),
  edge((1, 0), (1, 1), "->"),
  edge((0, 0), (1, 1), "->"),
  alt: "Arrows connect A to B, B to C, and A to C",
  caption: [A Fletcher diagram with a mandatory accessible description.],
)

The diagram's accessible description and caption remain stable across HTML
rebuilds.

#figure(
  table(
    columns: 3,
    table.header("Input", "Output", "Notes"),
    "HTML", "Web page", "Responsive",
    "PDF", "Document", "Paged",
    "Typst", "Source", "Shared",
  ),
  caption: [A table inside a figure.],
) <test-table>

The table reference @test-table checks its caption placement.

#theorem(topic: [Cancellation])[
  If $a b = a c$, then $b = c$.

  - This theorem contains a list.
  - List items should wrap normally in both outputs.
] <later-theorem>

== Alerts

#note[
  A note provides supporting context without interrupting the main argument.
]

#tip[
  Tip: write the semantic structure first, then adjust the visual styling.
]

#important[
  Important: draft posts are compiled for validation but are not published.
]

#warning[
  Warning: Typst HTML export is still experimental.
]

#caution[
  Caution: never publish private material by setting its draft flag to false.
]

== Footnotes <footnotes>

The custom HTML renderer places footnote text at the end of the article and
keeps a return link to the reference. Here is a footnote reference#footnote[
  The footnote body is available in both the HTML preview panel and the PDF.
] and another one#footnote[https://example.com #lorem(50) @typst-html-2026].

The reference @footnotes points to the generated footnote section.

== Embeds

Raw HTML can be used for a small third-party embed placeholder:

```typst
#raw_html(`<blockquote class="example-embed"><p>Embedded HTML content.</p></blockquote>`)
```

#raw_html(`<blockquote class="example-embed"><p>Embedded HTML content.</p></blockquote>`)

The YouTube helper accepts a full URL and an optional start time:

```typst
#youtube("https://www.youtube.com/watch?v=eWw8HoNkVkU", start: 30)
```

#youtube("https://www.youtube.com/watch?v=eWw8HoNkVkU", start: 30)

#bibliography("reference.bib")

// A line comment is part of the fixture.

/* A block comment is part of the fixture too. */
