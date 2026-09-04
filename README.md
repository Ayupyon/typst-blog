# Rin's template

这是 Ayupyon 的个人学习记录博客。每篇文章只有一份 Typst 源文件，同时生成：

- GitHub Project Pages 上的响应式语义 HTML；
- 与文章并列的 `post.pdf` 分页 PDF。

站点地址：<https://Ayupyon.github.io/typst-blog/>
源码仓库：<https://github.com/Ayupyon/typst-blog>

## 本地设置

要求：Git、Typst 0.15.1、Node.js 20+、uv 0.12.9，以及 Python 3.10+。本机已验证 Python 3.14 和 Node.js 20。

```sh
git clone --recurse-submodules https://github.com/Ayupyon/typst-blog.git
cd typst-blog
uv sync --frozen
```

在本工作区中，`uv` 的共享环境位于仓库外的 `/home/rin/WorkField/blog/.venv`；这是本机设置，不要把绝对路径写入提交或 CI。若需要复现本机环境，可运行：

```sh
export UV_PROJECT_ENVIRONMENT=/home/rin/WorkField/blog/.venv
uv venv "$UV_PROJECT_ENVIRONMENT" --python 3.14
uv sync --frozen
```

Typst 是外部 CLI，不由 Python 项目安装。确认版本：

```sh
uv run python --version
typst --version
node --version
```

## 编写文章

文章放在 `posts/<ascii-slug>/index.typ`。slug 必须是稳定的小写 ASCII kebab-case，例如 `category-theory-notes`。文章只从根 facade 导入，不直接导入核心引擎、Rin 或 Fletcher：

```typst
#import "/template.typ": post, calver, theorem, proof

#show: post.with(
  slug: "category-theory-notes",
  title: "函子与自然变换",
  course: "范畴论",
  create: calver(2026, 9, 4),
  description: "关于函子和自然变换的学习笔记。",
  tags: ("数学", "学习记录"),
  draft: true,
)

= 第一节

#theorem(topic: [自然性])[
  在这里写定理内容。
  #proof[在这里写证明。]
] <naturality>

引用：@naturality。
```

`course` 可省略。存在时，网页标题、H1、SEO、RSS、首页、标签页和搜索索引均使用 `Course · Title`；省略时只使用 `Title`。`author` 默认是 `Ayupyon`，`draft` 默认是 `true`。

根 facade re-export：`post`、`calver`、`definition`、`theorem`、`lemma`、`proof`、`diagram`、`env`、本地化提示框和嵌入 helper。定理、定义和引理在两个输出中保留按一级标题重置的编号与同文引用。

Fletcher 图必须提供非空 `alt`：

```typst
#diagram(
  node((0, 0), [A]),
  node((1, 0), [B]),
  edge((0, 0), (1, 0), "->"),
  alt: "箭头从对象 A 指向对象 B",
  caption: [一个简单的态射图。],
)
```

## 构建、预览与测试

推荐的生产命令会依次生成 HTML、验证所有文章的 PDF、只发布非草稿 PDF、插入 `下载 PDF` 链接、构建 Pagefind，并检查输出和站内链接：

```sh
export UV_PROJECT_ENVIRONMENT=/home/rin/WorkField/blog/.venv
uv run python scripts/build_site.py
```

其他常用命令：

```sh
uv run python command.py preview             # 含草稿的本地预览
uv run python command.py build               # 仅生产 HTML
uv run python scripts/build_pdfs.py --mode validation
uv run pytest
npx -y pagefind@1.5.2 --site public
```

`posts/feature-matrix` 和 `posts/title-fallback` 始终是草稿：它们在 CI 中编译并验证，但不会出现在生产 HTML、PDF、RSS、sitemap 或 Pagefind 中。`posts/hello-dual-output` 是最小的已发布示例。

## 发布规则

- `draft: false` 的文章必须同时拥有 `public/<slug>/index.html` 和 `public/<slug>/post.pdf`。
- PDF 链接使用相对地址 `post.pdf`，适用于 Project Pages 的 `/typst-blog/` base path。
- 草稿在预览中可见并带有 `noindex`，生产输出中完全不生成。
- GitHub Actions 在 Pull Request 中执行完整验证；推送到 `main` 或手动触发时上传 Pages artifact 并部署。
- `vendor/typst-blog-core` 和 `vendor/rin-template` 都是固定提交的 Git submodule；Rin 当前固定在 `0.3.0`。

## 从旧 Rin 文档迁移

1. 将正文移动到 `posts/<ascii-slug>/index.typ`。
2. 把旧的 `conf(...)` 顶层 header 换成根 facade 的 `post.with(...)`。
3. 补充 slug、创建日期、描述、标签和 draft 状态；保留正文中的标签、引用、公式和文献。
4. 将 Fletcher 原始调用换成 `diagram(...)` 并填写 `alt`；跨文章引用改用普通站内 URL。
5. 分别运行 HTML 与 PDF 构建，检查编号、引用、链接和可访问性。

旧的 Rin `conf(...)` 仍在 `vendor/rin-template` 中保留，用于只生成分页 PDF 的遗留文档。

## 已知限制

Typst HTML 导出仍在持续开发；HTML 打印不是 PDF 的替代品。Fletcher 的 SVG 图形本身不会被 Pagefind 理解，因此重要关系必须写在 `alt`、caption 或邻近正文中。自定义的 `typst/core/` 页面副本只修正 Typst 对 `zh-CN` 的语言代码限制，核心 submodule 本身不应直接编辑。
