#import "/template.typ": post, calver, theorem, proof

#show: post.with(
  slug: "hello-dual-output",
  title: "第一篇双输出记录",
  course: "Typst",
  create: calver(2026, 9, 4),
  description: "一份同时发布为语义 HTML 和分页 PDF 的中文学习记录。",
  tags: ("学习记录", "Typst"),
  draft: false,
)

= 从一份源文件开始

这篇短文验证个人博客的基本发布流程：网页保留语义结构，PDF 保留分页排版。

#theorem(topic: [双输出])[
  同一份文章源文件可以生成两种面向不同阅读场景的输出。

  #proof[网页适合检索与无障碍阅读，PDF 适合下载和打印。]
] <dual-output-theorem>

引用这个结论：@dual-output-theorem。
