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
