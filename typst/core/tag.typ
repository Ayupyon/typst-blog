#import "/site.typ": site
#import "/vendor/typst-blog-core/typst/core/shared.typ": export-target, main-font, heading-font, base-path
#import "/vendor/typst-blog-core/typst/core/i18n.typ": i18n
#import "/vendor/typst-blog-core/typst/components/head.typ": common-head
#import "/vendor/typst-blog-core/typst/components/page-layout.typ": page-layout
#import "/vendor/typst-blog-core/typst/components/post-cards.typ": post-card-grid
#import "/vendor/typst-blog-core/typst/components/widgets.typ": widget-mobile-search, widget-site-sidebar

#let tag-page(
  tag: "",
  tag-slug: "",
  posts: (:),
  body,
) = context {
  let page-title = "#" + tag + " | " + site.title
  set document(title: page-title, author: site.author.name)
  set text(lang: "zh")

  if export-target() == "paged" {
    set text(font: main-font, size: 12pt)
    show heading: set text(font: heading-font)
    body
    return
  }

  page-layout(
    head-content: {
      common-head(page-title, url: "/tags/" + tag-slug + "/")
    },
    main-content: {
      html.header(class: "article-header", {
        html.a(class: "back-home-btn", href: base-path + "/", i18n.back_home)
        html.h1(class: "article-title", {
          html.span(class: "tag-page-prefix", i18n.tags + " / ")
          "#" + tag
        })
      })

      widget-mobile-search()
      post-card-grid(posts)
    },
    sidebar-content: widget-site-sidebar(),
  )
}
