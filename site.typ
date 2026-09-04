#import "/vendor/typst-blog-core/typst/core/site-impl.typ": _site

#let site = _site(
  title: "Rin's blog",
  description: "Rin's study record",
  base_url: "https://Ayupyon.github.io/typst-blog",
  github_repo: "https://github.com/Ayupyon/typst-blog",
  language: "zh-CN",
  theme: "rin-dark",
  posts_dir: "posts",
  update_policy: "git",
  fonts: (
    main: (
      pdf: ("Libertinus Serif", "Noto Serif CJK SC", "Noto Serif CJK JP"),
      web: ("Libertinus Serif", "Noto Serif SC", "Noto Serif CJK SC", "Songti SC", "STSong"),
      weights: "400;700",
      fallback: "serif",
    ),
    code: (
      pdf: ("Fira Code", "FiraCode Nerd Font", "Noto Sans Mono CJK SC", "monospace"),
      web: ("Fira Code",),
      weights: "300..700",
      fallback: "monospace",
    ),
  ),
  author: (
    name: "Ayupyon",
    bio: "",
    socials: (
      x: "",
      misskey: "",
      github: "https://github.com/Ayupyon",
    ),
  ),
  analytics: (
    cloudflare_token: none,
  ),
  feedback: (
    google_form_url: none,
    entry_id: none,
  ),
  share: (
    x: false,
    misskey: false,
    copy: true,
  ),
)

#metadata(site) <site-meta>
