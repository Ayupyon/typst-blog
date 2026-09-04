#import "/template.typ": post, calver

// Phase 0 integration fixture. Later phases extend this draft with Rin blocks,
// references, Fletcher diagrams, images, code, tables, notes, and citations.
#show: post.with(
  slug: "feature-matrix",
  title: "双输出功能矩阵",
  create: calver(2026, 9, 4),
  description: "用于验证 HTML 与 PDF 双输出能力的草稿文章。",
  tags: ("Typst", "集成测试"),
  draft: true,
)

= 基线

此文章是集成测试契约，始终保持草稿状态，但会在持续集成中编译。
