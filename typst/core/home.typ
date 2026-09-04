#import "/site.typ": site
#import "/vendor/typst-blog-core/typst/core/shared.typ": export-target, main-font, heading-font
#import "/vendor/typst-blog-core/typst/components/head.typ": common-head
#import "/vendor/typst-blog-core/typst/components/page-layout.typ": page-layout
#import "/vendor/typst-blog-core/typst/components/post-cards.typ": post-card-grid
#import "/vendor/typst-blog-core/typst/components/widgets.typ": widget-mobile-search, widget-site-sidebar

#let home(
  title: none,
  authors: none,
  description: none,
  og-image: none,
  posts: none,
  body,
) = context {
  let page-title = if title == none { site.title } else { title }
  let page-description = if description == none { site.description } else { description }
  let document-authors = if authors == none { (site.author.name,) } else { authors }

  set document(title: page-title, author: document-authors)
  set text(lang: "zh")

  if export-target() == "paged" {
    set text(font: main-font, size: 12pt, lang: "zh")
    show heading: set text(font: heading-font)
    body
    return
  }

  page-layout(
    head-content: {
      common-head(page-title, description: page-description, image: og-image, url: "/")
    },
    main-content: {
      html.header(class: "article-header", {
        html.h1(class: "article-title", page-title)
        if page-description != "" {
          html.p(style: "color: var(--text-muted);", page-description)
        }
      })

      widget-mobile-search()
      post-card-grid(posts)
    },
    sidebar-content: widget-site-sidebar(),
  )
}
