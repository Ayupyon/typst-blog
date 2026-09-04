#import "/template.typ": post, calver

#show: post.with(
  slug: "title-fallback",
  title: "没有课程的文章",
  create: calver(2026, 9, 3),
  description: "验证没有 course 时网页标题只使用 title。",
  tags: ("测试",),
  draft: true,
)

= 标题回退

没有提供课程时，网页、订阅源和搜索索引都应使用“没有课程的文章”。
