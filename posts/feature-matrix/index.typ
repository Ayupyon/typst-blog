#import "/template.typ": (
  post, calver,
  definition, theorem, lemma, proof, diagram, node, edge,
  note, tip, important, warning, caution, raw_html,
)

#show: post.with(
  slug: "feature-matrix",
  title: "双输出功能矩阵",
  course: "Typst 集成",
  create: calver(2026, 9, 4),
  description: "用于验证 HTML 与 PDF 双输出能力的综合草稿文章。",
  tags: ("Typst", "集成测试", "中文"),
  abstract: "这篇文章覆盖定理块、引用、公式、图表、代码、脚注、文献和 Fletcher 图表。",
  draft: true,
)

= 第一节：共享语义

本文使用一份 Typst 源文件，同时生成语义 HTML 和分页 PDF。下面的前向引用指向稍后出现的定理：@later-theorem。

#definition(topic: [群])[
  群是带有结合运算、单位元和逆元的集合。
] <group-definition>

#theorem(topic: [单位元])[
  群的单位元是唯一的。

  #proof[
    设 $e$ 与 $e'$ 都是单位元，则 $e = e e' = e'$。
  ]
] <first-theorem>

#theorem[
  群中每个元素的逆元都是唯一的。
] <inverse-theorem>

#lemma[
  对任意群元素 $a$，有 $(a^(-1))^(-1) = a$。
] <first-lemma>

正文引用：@group-definition、@first-theorem、@inverse-theorem 和 @first-lemma。

== 公式、列表和代码

内联公式是 $a + b = b + a$，显示公式为：

$
  integral_0^1 x^2 dif x = 1 / 3
$

下面的长公式用于验证网页端的横向滚动：

$
  a_1 x_1 + a_2 x_2 + a_3 x_3 + a_4 x_4 + a_5 x_5 + a_6 x_6
    + a_7 x_7 + a_8 x_8 + a_9 x_9 + a_10 x_10 + a_11 x_11 + a_12 x_12 = b
$

- 第一项
  - 嵌套项目
  - 另一项
- 第二项

```typst
#let greeting(name) = [你好，#name！]
#greeting("Typst")
```

#note[补充信息应当在浅色主题中保持足够的对比度。]
#tip[提示：先写语义结构，再调整视觉样式。]
#important[重要：草稿不会进入生产站点。]
#warning[注意：HTML 导出仍处于实验阶段。]
#caution[警告：不要把私人内容标记为已发布。]

#tip[
  这段较长的提示用于验证分页 PDF 中的提示框可以自然跨页，并在下一页继续显示正文。

  标题应当和第一个正文片段保持在一起，正文则可以在页面边界处分开。这样既能保留
  框体的视觉层次，也不会因为内容较长而挤压页面中的其他内容。

  HTML 输出继续使用语义化的提示框结构，因此同一段内容在网页端仍然可以使用响应式
  布局和主题样式。PDF 输出只改变外层装饰，正文中的公式、链接和脚注仍保持原有语义。

  这是一个刻意较长的示例，实际文章中的提示框可以包含说明、列表或多段推导。渲染器
  应该让这些内容按照 Typst 的正常分页规则流动，而不是把整块内容限制在单页中。

  当提示框靠近页尾时，边框和背景也应该在分页处正确收束，并在下一页重新开始。标题
  不应单独留在页尾，正文的首段需要和标题一起出现，便于读者理解这段提示的范围。

  这段文字继续填充测试框体的可分页区域。它不代表新的 API，只是确保普通段落、中文
  标点和换行同时存在时，分页结果仍然稳定，且不会截断字符或覆盖页眉页脚。

  如果内容中包含内联公式，例如 $a + b = c$，公式应继续由 Typst 排版并保持可复制。
  颜色和边框只负责表达提示类型，不应该改变正文的字体、链接颜色或数学排版方式。

  最后一段用于把框体推到下一页附近，验证分页算法在实际文章长度下的表现。完成测试后，
  作者仍然可以使用同样的提示函数编写较短内容，短内容会继续保持紧凑的单页框体。

  分页测试还要覆盖连续的中文段落。每个段落都应该保留相同的内边距，让背景色在正文
  周围形成清晰的区域，并让边框沿着每个页面的可用宽度绘制。

  当框体跨越页面时，下一页的延续部分不需要重复标题，但必须继续显示边框和浅色背景。
  读者可以从标题和颜色判断这些段落属于同一个提示，而不必依赖额外的编号。

  页面顶部和底部可能有页眉、页脚以及脚注区域。框体应该遵守这些区域的布局约束，避免
  文字被裁剪，也避免边框覆盖页码或作者信息。

  这个 fixture 也帮助检查不同的字体尺寸和标点组合。中文全角标点、英文单词与数学符号
  混排时，行高应保持一致，内容仍然可以被 PDF 阅读器选择和复制。

  如果未来新增其他提示类型，可以沿用同一个渲染入口，只需要为类型选择颜色和图标。
  这能让 HTML 与 PDF 共享语义，同时允许两个输出目标使用各自合适的布局实现。

  提示框的内容可能包含链接、列表、公式或脚注。装饰层不能吞掉这些元素，因为它们在
  网页和文档中都承担导航、解释和无障碍阅读的作用。

  到达这里时，框体已经足够长，可以在普通纸张的页面边界处产生分页。测试结果应当是
  连续的正文和完整的视觉边界，而不是缩小字体或把整段内容截断。
]

= 第二节：媒体与引用 <section-two>

本节展示一个 #link(<section-two>)[内部标题链接] 和一个
#link("https://typst.app")[外部链接]。

#figure(
  image("./example-image.png", alt: "用于测试的中文示例图片"),
  caption: [本地 PNG 图片及其替代文本。],
) <raster-image>

#figure(
  image("./example-image.svg", alt: "HTML 与 PDF 由同一份源文件生成的示意图"),
  caption: [本地 SVG 图片。],
) <svg-image>

#diagram(
  node((0, 0), [对象 A]),
  node((1, 0), [对象 B]),
  node((1, 1), [对象 C]),
  edge((0, 0), (1, 0), "->"),
  edge((1, 0), (1, 1), "->"),
  edge((0, 0), (1, 1), "->"),
  alt: "箭头从对象 A 指向对象 B、从对象 B 指向对象 C，并从对象 A 指向对象 C",
  caption: [一个简单的态射图；邻近文字说明了图中的关系。],
)
<simple-diagram>

图表引用：@simple-diagram。

#theorem(topic: [消去律])[
  若 $a b = a c$，则 $b = c$。

  - 该定理包含列表。
  - 列表内容应当正常换行。

  #table(
    columns: (auto, auto, auto),
    table.header([输入], [输出], [备注]),
    [HTML], [网页], [响应式],
    [PDF], [文档], [分页],
  )
] <later-theorem>

#lemma[
  固定群元素的左乘是单射。
] <second-lemma>

脚注可以解释细节#footnote[脚注内容也应当出现在文章末尾，并带有返回链接。]，而引用使用 @typst-html-2026。

#bibliography("reference.bib")
