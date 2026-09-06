#import "/template.typ": (
  calver, definition, diagram, edge, lemma, node, note, post, proof, theorem,
  tip,
)

#show: post.with(
  slug: "llvm-domtree-build",
  title: "支配树构建",
  course: "LLVM",
  create: calver(2026, 9, 4),
  description: "支配树算法学习记录与LLVM相关源码阅读",
  tags: ("llvm", "compiler"),
  draft: true,
)

// Write the post body below.

本笔记基于LLVM 22.1.7版本源码编写。

= 数学定义

== 编译原理背景下的有向图

在编译原理所操作的控制流图的背景下，我们会对有向图加一些额外的条件限制。

#definition(topic: "编译原理背景下的有向图", [
  定义有向图$G = (V, E, s)$，其中$V$是$G$的节点集合，$E$是$G$的有向边集合，$s in V$，$G$满足：

  + 对任意$V$中的节点$v$，$s$可达$v$。
  + 对任意$V$中的节点$v$，$v$不存在指向$s$的边。
])

这两个限制在编译器的工作场景下都很好达成：

+ 编译器会在每个函数的入口插入entry基本块，指向函数逻辑的入口基本块。
+ 对于从entry基本块不可达的基本块，这些基本块在优化后一定会被清除掉，只需要在优化Pass执行时考虑它们带来的边界条件即可。

== 支配关系

支配关系是一个有向图上的偏序关系：

#definition(topic: "支配关系", [
  对有向图$G = (V, E, s)$，对任意节点$u, v in V$，称$u$*支配*$v$当且仅当从$s$到$v$的所有路径都必须经过$u$。

  记一个节点$v$的支配节点集合为$"dom"(v)$。
])

#tip[
  *注意*：在我们给出的有向图限制下，对任意$v in V - {s}$，一定有$s in "dom"(V)$。

  后文的支配树构建算法都依赖这个假定。
]


支配树的构建更加依赖“直接支配”这一概念，即非节点本身但是是离节点“最近”的支配节点：

#definition(topic: "直接支配节点", [
  对有向图上的一个节点$v$，如果一个节点$u$满足：

  $ u in "dom"(v) - {v} and forall w in "dom"(v) - {v}, w in "dom"(u) $

  称$u$为$v$的直接支配节点，记为$u = "idom"(v)$。
])

== 支配树

有了直接支配节点，即可顺势推出支配树的定义：

#definition(topic: "支配树", [
  对有向图$G = (V, E, s)$，其支配树定义为$T = (V, E^prime, s)$，其中：

  + $s$为$T$的根节点。
  + $E^prime = {(u, v) | u = "idom"(v) }$。
])

= 支配树构建算法

== naive构建

naive构建算法即为基于支配关系和支配树定义，对支配树进行构建的算法。

给定有向图$G = (V, E, s)$，naive算法的构建方式如下：

+ 按照父节点先于子节点的DFS序（如先序遍历或逆后序遍历）从$s$遍历所有节点，对遍历到的每个节点（记为$u$）执行：
  + 将其从$G$中删除（仅在本次遍历删除，遍历结束时恢复）
  + 再次从$s$开始遍历$G$，对于每个本次遍历不可达的节点，将$u$加入到它的支配节点列表中。
+ 对于每个节点，把它的支配节点列表中除了它本身之外的最后一个节点（$s$不存在这样的节点，自然是根节点），作为支配树的父节点构建整个支配树。

时间复杂度为$O(n(n + m))$，naive算法简单且利于理解支配树的定义，但是效率欠佳。

== 迭代式构建

迭代式构建算法基于以下对于支配关系的insight，将支配集合的构建变成了一个数据流分析问题：

#lemma([
  对任意有向图$G = (V, E, s)$中的节点$v$，$"dom"(v) = {v} union (inter.big_((u, v) in E) "dom"(u))$。
])

在这里先引入DFS遍历序数的概念，在迭代算法下序数只用于辅助寻找直接支配节点（不用它也可以做到），但是对于下一个算法，它是很重要的概念。

#definition(topic: "DFS遍历序数", [
  对于任意图$G = (V, E)$，使用特定DFS顺序遍历（如先序遍历，后序遍历，逆后序遍历）时，访问到的节点有特定的顺序。对节点$v in V$，记$"dfn"(v)$为它在此次DFS下的序数，构造方式为：

  记一个单调递增的时间戳值$t$，初始值为0，每次首次遍历到一个节点$v$时：
  + 令$"dfn"(v) = t$。
  + $t$自增1。
])

#tip[
  *注意*：在不同的DFS遍历顺序下，一个节点的DFS遍历序数可能不同。
]

给定有向图$G = (V, E, s)$，迭代式算法的构建方式如下：

+ 初始情况，对任意$v in V$，$"dom"(v) = {v}$。

+ 在每次迭代中，逆后序遍历$V$，对任意节点$v in V - {s}$，更新其$"dom"(v)$：

  $ "dom"(v) = {v} union (inter.big_((u, v) in E) "dom"(u)) $

+ 如果一次迭代中存在一个节点$v$的$"dom"(v)$改变，回到2，继续下一次迭代，否则进入4。

+ 对每个节点$v$，取$"dom"(v) - {v}$中，逆后序遍历下$"dfn"(u)$最大的$u$，$"idom"(v) = u$，根据这个结果构建支配树。

记$p$为数据流迭代的次数，因为我们使用了逆后序遍历的顺序迭代有向图，所以可以保证：

#note[
  在一次迭代中，如果一个节点的前驱节点所更新的支配节点也是它的支配节点，那么在这次迭代中这个支配节点一定可以更新到这个节点的支配节点集合中；反过来，如果一个节点的前驱节点的支配节点集合都不再更新，那么这个节点的支配节点集合也不再更新。
]

所以，对于每次产生了支配节点集合更新的迭代，一定是*每个会产生支配节点集合更新的节点，对应的支配节点集合都更新了*。所以$p = O(n)$。

对于单次迭代，可以使用bitset或者哈希集合维护每个节点的支配节点集合，时间复杂度为$O(n m)$。

所以迭代式构建的最坏时间复杂度为$O(p m n)$，看上去不比naive算法好，但是对于编译器实现来说，迭代需要更新的节点还可以使用worklist优化，同时对于常见的程序的控制流图结构而言，这个算法的收敛速度极快（通常只需要2到3次迭代），所以在编译器的应用场景下，这个算法的运行速度通常是很快的。

== Lengauer-Tarjan算法

Lengauer-Tarjan算法（简记为LT算法）是理论层面非常高效的支配树构建算法，时间复杂度为$O((n + m)log n)$。

LT算法通过引入“半支配节点”的概念，使得在有向图中可以高效地求解半支配节点，并且使用半支配节点高效地求解直接支配节点。

LT算法依赖DFS遍历序数进行半支配节点和直接支配节点的求解。后文所有的DFS遍历序数都指的是*先序遍历*有向图得到的序数。

后文使用$G = (V, E, s)$表示有向图，$T = (V, E^prime, s)$表示$G$通过先序遍历得到的生成树。

=== 半支配节点

先给出半支配节点的形式化定义：

#definition(topic: "半支配节点", [
  对有向图$G = (V, E, s)$，对任意$w in V$，$w$的半支配节点（记为$"sdom"(w)$）定义为：

  $
    "sdom"(w) = "argmin"{"dfn"(v) | "exists path" (v = v_0), v_1, v_2, dots, (v_k = w), "such that" forall 1 <= i <= k - 1, "dfn"(v_i) > "dfn"(w)}
  $

  其中，用于选取候选节点$v$的条件成为半支配节点的*路径条件*。
])

半支配节点可以形象的理解为：序数最小的可以不经过DFS得到的树边到达$w$的节点。

以下图表示的有向图为例：

#diagram(
  node((0, 0), $v_1$, stroke: 1pt, name: <1_v1>),
  node((1, 0), $v_2$, stroke: 1pt, name: <1_v2>),
  node((1, 1), $v_3$, stroke: 1pt, name: <1_v3>),
  node((2, 0), $v_4$, stroke: 1pt, name: <1_v4>),
  node((2, 1), $v_5$, stroke: 1pt, name: <1_v5>),
  edge(<1_v1>, <1_v2>, "->"),
  edge(<1_v1>, <1_v3>, "->"),
  edge(<1_v2>, <1_v3>, "->"),
  edge(<1_v2>, <1_v4>, "->"),
  edge(<1_v2>, <1_v5>, "->"),
  edge(<1_v3>, <1_v4>, "->"),
  edge(<1_v5>, <1_v4>, "->"),
  alt: "半支配节点有向图示例",
)

假设DFS顺序为$v_1, v_2, v_3, v_4, v_5$，则有：
$ "sdom"(v_2) = v_1, "sdom"(v_3) = v_1, "sdom"(v_4) = v_2, "sdom"(v_5) = v_2 $

半支配节点从直觉上可以有效地“过滤”在有向图的节点集合内可能是一个节点的支配节点的候选节点集合，通过下面两个引理形式化地说明：

#lemma[
  对任意$V - {s}$中的节点$u$，$"sdom"(u)$是$u$在$T$上的真祖先。

  #proof[
    设$v$是$u$的父节点，根据半支配节点的定义，可以知道$"dfn"("sdom"(u)) <= "dfn"(v)$。

    假设$"sdom"(u)$不是$u$的真祖先，那么在$T$中它只能在$u$所在子树的左侧子树中，然而因为$"sdom"(u)$存在到$u$的路径，所以此时$"sdom"(u)$不可能和$u$不在同一棵子树中，产生矛盾。
  ]
]

#lemma[
  对任意$V - {s}$中的节点$u$，$"idom"(u)$是$"sdom"(u)$在$T$上的祖先。

  #proof[
    根据支配节点的定义，可以知道$"idom"(u)$一定是$u$在$T$上的祖先。

    如果$"idom"(u)$不是$"sdom"(u)$的祖先，那只能是$"sdom"(u)$是$"idom"(u)$的真祖先。但是根据$"sdom"(u)$的定义，此时一定存在一条从$"sdom"(u)$到$u$的，不经过$"idom"(u)$的路径，与$"idom"(u)$的定义矛盾。
  ]
] <idom-u-to-sdom-u>

从而，我们可以把一个节点$u$的“候选”直接支配点集合缩小为：$"sdom"(u)$在$T$上的祖先节点。

但是只是这样的“过滤”还不足以大幅提升计算效率，下面给出一个在DFS生成树上的祖先节点和子节点和其各自的直接支配节点满足的性质，这个性质会帮助我们对后续加速计算直接支配节点的引理推导：

#lemma[
  对任意节点$w in V$，如果存在节点$v in V$使得$v$在$T$上是$w$的祖先，那么下面两种情况必定满足其一：
  + $v$是$"idom"(w)$的祖先。
  + $"idom"(w)$是$"idom"(v)$的祖先。

  #proof[
    假设上面两种情况均不成立，那么一定是：
    + $"idom"(w)$是$v$的真祖先。
    + $"idom"(v)$是$"idom"(w)$的真祖先。

    此时这四个节点构成一条链$"idom"(v) arrow.r dots arrow.r "idom"(w) arrow.r dots arrow.r v arrow.r dots arrow.r w$。

    因为$"idom"(w)$不支配$v$，所以一定存在一条从$"idom"(v)$到$v$的不经过$"idom"(w)$的路径$"idom"(v) arrow.r dots arrow.r v$，从而$s arrow.r dots arrow.r "idom"(v) arrow.r dots arrow.r v arrow.r dots arrow.r w$成为了一条不经过$"idom"(w)$从$s$到达$w$的路径，与$"idom"(w)$是$w$的支配节点矛盾。
  ]
]

这个引理说明了节点与它对应的直接支配节点在生成树上的独特结构。一个节点和它的祖先节点，以及它们对应的直接支配节点，*不可能在生成树从根出发到这个节点的链上交织出现*。

有了上面的铺垫，就可以引出半支配节点用于加速支配节点查询的两个关键引理了：

#lemma[
  对任意节点$w in V - {s}$，记$T$上从$"sdom"(w)$到$w$的路径为$P^prime = ("sdom"(w) = v^prime_0) arrow.r v^prime_1 arrow.r dots arrow.r v^prime_(k^prime - 1) arrow.r (v^prime_(k^prime) = w)$，如果$P^prime$满足：
  $
    forall i^prime in [1, k^prime - 1], "dfn"("sdom"(v^prime_(i^prime))) >= "dfn"("sdom"(w))
  $

  则$"idom"(w) = "sdom"(w)$。

  #proof[
    假设$"idom"(w) != "sdom"(w)$，根据@idom-u-to-sdom-u，$"idom"(w)$是$"sdom"(w)$的真祖先。因为$"sdom"(w)$不支配$w$，所以存在一条路径$P = "(idom"(w) = v_0) arrow.r v_1 arrow.r dots arrow.r v_(k - 1) arrow.r (v_k = w)$不经过$"sdom"(w)$。

    对$P$包含的节点进行讨论：
    + 如果对任意$i^prime in [1, k^prime - 1]$，$v^prime_(i^prime)$都不在$P$中，那么只能是$P$通过序数比$"dfn"(w)$大的节点到达$w$，此时一定存在$i in [1, k - 1]$满足：
      $
        forall j < i, "dfn"(v_j) < "dfn"(w); forall j >= i, "dfn"(v_j) > "dfn"(w)
      $

      因为$P^prime$的中间节点都不在$P$上，此时$"dfn"(v_(i - 1))$一定小于$"dfn"("sdom"(w))$，从而$"sdom"(w)$不满足半支配节点的定义，矛盾。

    + 如果存在$v^prime_(i^prime)$在$P$中，那么和情况1的推导类似，可以得到$"dfn"("sdom"(v^prime_(i^prime))) < "dfn"("sdom"(w))$，但是$v^prime_(i^prime)$是$w$的祖先，这和前提条件矛盾。
  ]
] <sdom-calc-idom-1>

用一句话来说就是：对于节点$w$，在$T$上从$"sdom"(w)$到$w$的所有节点，它们的半支配节点都在$"sdom"(w)$到$w$这条路径上，那么$"sdom"(w)$就是$"idom"(w)$。

那么，如果在这条路径上，有节点的半支配节点“逃出”了这条路径呢？下面的引理回答了这个问题：

#lemma[
  对任意节点$w in V - {s}$，记$T$上从$"sdom"(w)$到$w$的路径为$P^prime = ("sdom"(w) = v^prime_0) arrow.r v^prime_1 arrow.r dots arrow.r v^prime_(k^prime - 1) arrow.r (v^prime_(k^prime) = w)$，如果：

  $
    min{"dfn"("sdom"(v^prime_(i^prime))) | 1 <= i^prime <= k^prime - 1} < "dfn"("sdom"(w))
  $

  记$u = "argmin"{"dfn"("sdom"(v^prime_(i^prime))) | 1 <= i^prime <= k^prime - 1}$，有$"idom"(w) = "idom"(u)$。

  #proof[
    根据@idom-u-to-sdom-u，现在$u$是$w$的祖先但不是$"idom"(w)$的祖先，所以只能是$"idom"(w)$是$"idom"(u)$的祖先。

    假设$"idom"(w)$是$"idom"(u)$的真祖先，因为$"idom"(u)$不支配$w$，所以存在$"idom"(w)$到$w$的路径$P$，$P$不经过$"idom"(u)$。

    同时，在$T$上，从$"idom"(w)$到$w$的路径可表示为$P^* = "idom"(w) arrow.r dots arrow.r "idom"(u) arrow.r dots arrow.r "sdom"(u) arrow.r dots arrow.r "sdom"(w) arrow.r dots arrow.r u arrow.r dots arrow.r w$。

    如果在$P$上存在一个节点$y$，$y$在$"idom"(u) arrow.r dots arrow.r u$的路径之间，那么$"idom"(w) arrow.r dots arrow.r y arrow.r dots arrow.r u$是一条不经过$"idom"(u)$的路径，与$"idom"(u)$支配$u$矛盾。

    所以，$P$和$P^*$存在的相交的节点只能在$"idom"(w) arrow.r dots arrow.r "idom"(u)$和$u arrow.r dots arrow.r w$之间（不包含$u$），对$P$到达$w$经过的节点进行讨论：

    + 如果对任意$i^prime in [1, k^prime - 1]$，$v^prime_(i^prime)$都不在$P$上，和@sdom-calc-idom-1
      的情况1类似，这个时候$"sdom"(w)$不满足半支配节点的定义，矛盾。
    + 如果存在$y = v^prime_(i^prime)$，$y$在$P$上，那么$y$只能在$u arrow.r dots arrow.r w$的中间节点上。不妨设$y$是路径$P$进入到$u arrow.r dots arrow.r w$这一段路径的第一个节点。

      按照$u$的定义，$"dfn"("sdom"(y)) >= "dfn"("sdom"(u))$，所以这条路径也是$"idom"(w)$到$y$的不经过$"sdom"(y)$的路径，同时因为$y$是路径$P$进入到$u arrow.r dots arrow.r w$这一段路径的第一个节点，所以$P$上不再存在$u arrow.r dots arrow.r y$路径上的节点，此时对于$"sdom"(y)$到$y$在$T$上的路径，又一次变为了@sdom-calc-idom-1
      的情况1，此时$"sdom"(y)$不满足半支配节点的定义，矛盾。
  ]
]

即，如果在$T$上，从$"sdom"(w)$到$w$的路径上，存在半支配节点“逃出”了这条路径，那么$w$的直接支配节点和这条路径上，半支配节点序数最小的那个节点的直接支配节点相同。

让我们用下面的定理总结上面两个引理的结论。

#theorem[
  对任意$w in V - {s}$，设路径$P = ("sdom"(w) = v_0) arrow.r v_1 arrow.r dots arrow.r v_(k - 1) arrow.r (v_k = w)$。

  设$u = "argmin"{"dfn"("sdom"(v_i)) | 1 <= i <= k}$，有：

  $
    "idom"(w) = cases(
      "sdom"(w) " if" "dfn"("sdom"(w)) = "dfn"("sdom"(u)),
      "idom"(u) " otherwise"
    )
  $
] <sdom-calc-idom-result>

是一个很简洁的状态转移方程，但是想要高效地计算这个状态转移还剩下两个问题：

+ 怎么高效地计算半支配节点？
+ 怎么高效地计算$u$？

马上解决这两个问题。

=== 求解半支配节点和直接支配节点

下面的定理给出了半支配节点的迭代式定义：

#theorem[
  对任意$w in V - {s}$：
  $
    "sdom"(w) = "argmin"{"dfn"(v) | v in U_1 union U_2 } \
    U_1 = {u | (u, w) in E and "dfn"(u) < "dfn"(w)} \
    U_2 = {"sdom"(u) | "dfn"(u) > "dfn"(w) and ((v, w) in E and u "is ancestor of" v "in" T) }
  $

  #proof[
    设$t_1 = "dfn"("sdom"(w)), t_2 = min{"dfn"(v) | v in U_1 union U_2}$。

    + 证明$t_1 <= t_2$：只需证明对任意$u in U_1 union U_2$，$u$满足半支配节点的路径条件。
      + 对任意$u in U_1$，路径$u arrow.r w$自然满足条件。
      + 对任意$u in U_2$，令$u = "sdom"(u^prime)$，因为$u arrow.r dots arrow.r u^prime$的中间节点的序数都大于$"dfn"(u^prime)$，所以路径$u arrow.r dots arrow.r u^prime arrow.r dots arrow.r v arrow.r w$满足条件。
    + 证明$t_1 >= t_2$：设路径$P = ("sdom"(w) = v_0) arrow.r v_1 arrow.r dots arrow.r v_(k - 1) arrow.r (v_k = w)$，$P$满足半支配节点的路径条件。对$k$的大小做讨论：

      在路径$P$中，选择最小的$j$使得$v_j$在$T$上是$v_(k - 1)$的祖先，这样的$j$一定存在，因为$j = k - 1$满足条件。

      此时，对任意$1 <= i < j$，有$"dfn"(v_i) > "dfn"(v_j)$，如果存在$"dfn"(v_i) < "dfn"(v_j)$并且$v_i, v_j$之间存在路径，那么$v_i$在$T$上一定是$v_j$的祖先，与$j$是最小的满足$v_j$是$v_(k - 1)$的祖先的值矛盾。

      所以此时$v_j in U_2$，并且根据半支配节点的定义，$"sdom"(w)$满足$v_j$的半支配节点的路径条件，所以$"dfn"("sdom"(v_j)) <= "dfn"("sdom"(w))$，而$t_2 <= "dfn"("sdom"(v_j))$，所以$t_2 <= "dfn"("sdom"(w)) = t_1$。

    综上，$t_1 = t_2$，从而$"sdom"(w)$和$"argmin"{"dfn"(v) | v in U_1 union U_2 }$只能是同一个节点。
  ]
] <sdom-calculation-theorem>

对于$U_1$，很好维护，只需要遍历有向图时，对每个遍历到的节点（无论是不是第一次遍历到），都使用遍历到它的来源节点的序数更新最小序数对应的来源节点即可。

对于$U_2$，如果要高效地维护，可以借助并查集这一数据结构，使用以下的方法：
+ 根据DFS序数，倒序遍历节点。
+ 遍历到当前节点时，在已遍历节点组成的节点集合相对于$T$的生成森林子图中，使用并查集的find操作即可顺着每个节点的祖先链，找到这个节点的祖先节点（除了当前节点所在子树的根节点）中半支配节点序数最小的节点。（为了高效，需要使用并查集的路径压缩操作）
+ 遍历到当前节点时，使用并查集的merge操作，将当前节点merge到$T$中的父节点上（*注意*：这里的merge是*有序*的）。

#tip[
  我们常见的并查集应用都是应用于无向图的，一个有序的并查集并不太常见，所以这里的维护操作可能需要仔细思考一下。
]

到了这一步，不知道是巧合还是半支配节点的巧妙性质，我们对于一个节点$w$，如果想使用@sdom-calc-idom-result
的表述计算这个节点的支配节点，那么只需要使用上述维护$U_2$的过程中倒序遍历到$"sdom"(w)$时的生成森林状况下维护的并查集信息即可！

参考实现见#link("https://www.luogu.com.cn/record/293123106")[Luogu P5180
  Rust实现]中的`DominatorTreeCalculator`结构体实现，这个实现对应的是更一般的有向图场景。

== Semi-NCA算法——LLVM标准实现

LT算法的时间复杂度很不错，但是它最后没有成为工业实现的标准，我觉得可能有两个原因：
+ 半支配节点和直接支配节点的计算需要耦合到一次遍历里面，与工业界的模块化逻辑不太契合。
+ LT算法需要维护一系列查询和反查询的数据结构，如上面Rust实现中的：
  - `g`和`rg`
  - `dfn`和`dfn_rev`
  - `sdom`和`sdom_rev`
  其中反向图建立难以避免，`dfn`映射由于是一对一的所以尚可接受，但是半支配节点的映射因为可以多对一，所以`sdom_rev`也需要和反向图一样使用一个二维列表的数据结构，对于工业实现有点重了。

LLVM最终用于支配树构建的标准实现使用的是Semi-NCA算法，它吸取了LT算法的半支配节点的计算和使用，但解耦了半支配点计算和直接支配节点的计算过程，并且省下了`sdom_rev`数据结构的维护。

#tip[
  什么是NCA？你可能没见过这个，但是你更有可能见过LCA（least common
  ancestor，最近公共祖先），其实NCA（nearest common
  ancestor）就和LCA是一个东西。
]

Semi-NCA算法，顾名思义，“Semi”指半支配节点，“NCA”指最近公共祖先，所以可以理解成“使用半支配节点和最近公共祖先计算支配树”的算法。

Semi-NCA算法使用了下面的insight来解耦半支配节点和直接支配节点的计算：

#lemma[
  对有向图$G = (V, E, s)$，它的DFS生成树为$T$，对任意节点$w in V - {s}$，有：
  $ forall u in "dom"(w), u in "dom"("sdom"(w)) inter "dom"("parent"_T (w)) $

  #proof[
    记$U = "dom"("sdom"(w)) inter "dom"("parent"_T (w))$。
    + 证明$"dom"(w) subset.eq U$：假如存在$w$的支配节点$u$，不支配$"sdom"(w)$或不支配$"parent"_T (w)$，假设它不支配$"sdom"(w)$，那么从$s$存在一条不经过$u$的路径$s arrow.r dots arrow.r "sdom"(w)$，根据半支配节点的路径条件，存在路径$s arrow.r dots arrow.r "sdom"(w) arrow.r dots arrow.r w$，与$u$支配$w$矛盾，假设它不支配$"parent"_T (w)$的情况同理。
    + 证明$U subset.eq "dom"(w)$，假设存在$u in U$，$u$不支配$w$，那么此时在$T$上，$"idom"(w)$一定是$u$的真祖先，而$"idom"(w)$存在不经过$u$到达$w$的路径，从而$"idom"(w)$到$w$的这条路径一定不经过$T$上$u arrow.r dots arrow.r "sdom"(w) arrow.r dots "parent"_T (w)$上的任何一个节点。所以这条路径一定是通过比$w$序数大的节点到达$w$的，此时和@sdom-calc-idom-1
      情况一的路径属于相同的情形，从而与$"sdom"(w)$是$w$的半支配节点矛盾。
    综上，$"dom"(w) = U$。
  ]
]

上面的结论说明，在支配树上，$w$的支配节点一定是$"sdom"(w)$和$"parent"_T (w)$的公共祖先，计算$w$的直接支配节点自然就变成了计算这两个节点的最近公共祖先：

#theorem([
  对有向图$G = (V, E, s)$，它的DFS生成树为$T$，支配树为$D$，对任意节点$w in V - {s}$：
  $ "idom"(w) = "NCA"_D ("sdom"(w), "parent"_T (w)) $

  即：一个节点的直接支配节点，是它的半支配节点与它在DFS生成树上的父节点，在支配树上的最近公共祖先。
])

这样，在计算完每个节点的半支配节点之后，我们只需要按照DFS序数，顺序计算每个节点的直接支配节点即可。

下面通过LLVM源码进行讲解。

=== 驱动代码

支配树构建逻辑位于分析Pass：`DominatorTreeAnalysis`中，通过`run`方法驱动，为一个函数的控制流图构建支配树。

```cpp
// llvm/include/llvm/IR/Dominators.h:282~293
/// Analysis pass which computes a \c DominatorTree.
class DominatorTreeAnalysis : public AnalysisInfoMixin<DominatorTreeAnalysis> {
  friend AnalysisInfoMixin<DominatorTreeAnalysis>;
  LLVM_ABI static AnalysisKey Key;

public:
  /// Provide the result typedef for this analysis pass.
  using Result = DominatorTree;

  /// Run the analysis pass over a function and produce a dominator tree.
  LLVM_ABI DominatorTree run(Function &F, FunctionAnalysisManager &);
};
```

`run`方法是对`DominatorTree::recalculate`方法的一层包装：

```cpp
// llvm/lib/IR/Dominators.cpp:384~389
DominatorTree DominatorTreeAnalysis::run(Function &F,
                                         FunctionAnalysisManager &) {
  DominatorTree DT;
  DT.recalculate(F);
  return DT;
}
```

`DominatorTree::recalculate`方法重置当前支配树指向的函数，调用`DomTreeBuilder`
namespace下的 `Calculate`函数计算支配树。

```cpp
// llvm/include/llvm/Support/GenericDomTree.h:857~862
  /// recalculate - compute a dominator tree for the given function
  void recalculate(ParentType &Func) {
    Parent = &Func;
    updateBlockNumberEpoch(); // 暂时不用关心
    DomTreeBuilder::Calculate(*this);
  }
```

`Calculate`函数是`SemiNCAInfo::CalculateFromScratch`方法的包装。

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:1551~1554
template <class DomTreeT>
void Calculate(DomTreeT &DT) {
  SemiNCAInfo<DomTreeT>::CalculateFromScratch(DT, nullptr);
}
```

`CalculateFromScratch`方法里面包含了所有构建支配树的逻辑。

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:560~597
  static void CalculateFromScratch(DomTreeT &DT, BatchUpdatePtr BUI) {
    auto *Parent = DT.Parent;
    DT.reset();
    DT.Parent = Parent;
    // If the update is using the actual CFG, BUI is null. If it's using a view,
    // BUI is non-null and the PreCFGView is used. When calculating from
    // scratch, make the PreViewCFG equal to the PostCFGView, so Post is used.
    BatchUpdatePtr PostViewBUI = nullptr;
    if (BUI && BUI->PostViewCFG) {
      BUI->PreViewCFG = *BUI->PostViewCFG;
      PostViewBUI = BUI;
    }
    // This is rebuilding the whole tree, not incrementally, but PostViewBUI is
    // used in case the caller needs a DT update with a CFGView.
    SemiNCAInfo SNCA(PostViewBUI);

    // Step #0: Number blocks in depth-first order and initialize variables used
    // in later stages of the algorithm.
    DT.Roots = FindRoots(DT, PostViewBUI);
    SNCA.doFullDFSWalk(DT, AlwaysDescend);

    SNCA.runSemiNCA();
    if (BUI) {
      BUI->IsRecalculated = true;
      LLVM_DEBUG(
          dbgs() << "DomTree recalculated, skipping future batch updates\n");
    }

    if (DT.Roots.empty()) return;

    // Add a node for the root. If the tree is a PostDominatorTree it will be
    // the virtual exit (denoted by (BasicBlock *) nullptr) which postdominates
    // all real exits (including multiple exit blocks, infinite loops).
    NodePtr Root = IsPostDom ? nullptr : DT.Roots[0];

    DT.RootNode = DT.createNode(Root);
    SNCA.attachNewSubtree(DT, DT.RootNode);
  }
```

`SemiNCAInfo`类是一个通用的，通过Semi-NCA算法计算支配树的框架，支持抽象的有向图节点，以及正向与反向支配树的构建，在这里我们只关心在控制流图上的正向支配树的构建，此时`FindRoots`方法总是返回入口基本块。

这个方法中用于构建支配树的最关键步骤是：
+ 调用`doFullDFSWalk`方法，求出所有基本块的DFS序数。
+ 调用`runSemiNCA`方法求出所有基本块的直接支配节点。
+ 调用`attachNewSubtree`方法构建支配树。

=== 关键数据结构

`SemiNCAInfo`结构体中使用下面两个字段保存计算半支配节点和支配节点所需要的信息：

+ `NumToNode`：`llvm/include/llvm/Support/GenericDomTreeConstruction.h:75`

  类型为保存`NodePtr`的`SmallVector`，用于通过DFS序数查找对应的节点，初始化时会在下标为0的位置保存一个`nullptr`的dummy节点，所以后续

+ `NodeInfos`：`llvm/include/llvm/Support/GenericDomTreeConstruction.h:78~80`

  它用于保存节点指向它对应的`InfoRec`结构体的映射，如果节点有数字id，那么它是一个`InfoRec`的列表，否则是一个节点指针到`InfoRec`实例的`DenseMap`。

  将一个节点传入到`SemiNCAInfo::getNodeInfo`方法中可以获得这个节点映射到的`InfoRec`指针。

`InfoRec`结构体定义如下：

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:63~71
  // Information record used by Semi-NCA during tree construction.
  struct InfoRec {
    unsigned DFSNum = 0;
    unsigned Parent = 0;
    unsigned Semi = 0;
    unsigned Label = 0; // 等价于rust实现中的 node_with_min_sdom 字段
    NodePtr IDom = nullptr;
    SmallVector<unsigned, 4> ReverseChildren;
  };
```

就是计算半支配点和支配点所需要的信息集合。

=== 计算DFS序数

`doFullDFSWalk`方法是对`runDFS`方法的包装：

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:547~558
  template <typename DescendCondition>
  void doFullDFSWalk(const DomTreeT &DT, DescendCondition DC) {
    if (!IsPostDom) {
      assert(DT.Roots.size() == 1 && "Dominators should have a singe root");
      runDFS(DT.Roots[0], 0, DC, 0);
      return;
    }

    addVirtualRoot();
    unsigned Num = 1;
    for (const NodePtr Root : DT.Roots) Num = runDFS(Root, Num, DC, 1);
  }
```

因为我们只关注正向支配树的构建，所以只需要看`if (!IsPostDom)`内部的逻辑即可。

`runDFS`方法是一个高度模板化的非递归DFS实现，允许调用者以各种自定义的方式调用DFS并计算对应的序数：

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:184~229
  // Custom DFS implementation which can skip nodes based on a provided
  // predicate. It also collects ReverseChildren so that we don't have to spend
  // time getting predecessors in SemiNCA.
  //
  // If IsReverse is set to true, the DFS walk will be performed backwards
  // relative to IsPostDom -- using reverse edges for dominators and forward
  // edges for postdominators.
  //
  // If SuccOrder is specified then in this order the DFS traverses the children
  // otherwise the order is implied by the results of getChildren().
  template <bool IsReverse = false, typename DescendCondition>
  unsigned runDFS(NodePtr V, unsigned LastNum, DescendCondition Condition,
                  unsigned AttachToNum,
                  const NodeOrderMap *SuccOrder = nullptr) {
    assert(V);
    SmallVector<std::pair<NodePtr, unsigned>, 64> WorkList = {{V, AttachToNum}};
    getNodeInfo(V).Parent = AttachToNum;

    while (!WorkList.empty()) {
      const auto [BB, ParentNum] = WorkList.pop_back_val();
      auto &BBInfo = getNodeInfo(BB);
      BBInfo.ReverseChildren.push_back(ParentNum);

      // Visited nodes always have positive DFS numbers.
      if (BBInfo.DFSNum != 0) continue;
      BBInfo.Parent = ParentNum;
      BBInfo.DFSNum = BBInfo.Semi = BBInfo.Label = ++LastNum;
      NumToNode.push_back(BB);

      constexpr bool Direction = IsReverse != IsPostDom;  // XOR.
      auto Successors = getChildren<Direction>(BB, BatchUpdates);
      if (SuccOrder && Successors.size() > 1)
        llvm::sort(
            Successors.begin(), Successors.end(), [=](NodePtr A, NodePtr B) {
              return SuccOrder->find(A)->second < SuccOrder->find(B)->second;
            });

      for (const NodePtr Succ : Successors) {
        if (!Condition(BB, Succ)) continue;

        WorkList.push_back({Succ, LastNum});
      }
    }

    return LastNum;
  }
```

各个参数的含义为：

- `V`：DFS入口节点。
- `LastNum`：上一次DFS时最后一个访问的节点的序数，可能用于同时对多个连通分支进行DFS的情况。
- `Condition`：谓词回调函数，用于判断一个节点是否需要被DFS访问。
- `AttachToNum`：当前DFS生成树的根节点，需要以之前DFS遍历到的节点中的哪一个节点，作为它的父节点。
- `SuccOrder`：从一个节点开始访问其相邻节点时，访问相邻节点的顺序，如果没有指定就按默认的邻接节点顺序。

最后返回值为此次遍历结束后最后一个节点的DFS序数。

这里的DFS逻辑并不复杂，主要就是用一个worklist栈模拟了DFS的递归栈，如果熟悉DFS的处理过程的话并不难理解。只需要注意`NumToNode`维护的DFS序数是从1开始的。

=== 计算半支配节点和直接支配节点

计算半支配节点和直接支配节点的逻辑位于`runSemiNCA`函数中：

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:275~319
  // This function requires DFS to be run before calling it.
  void runSemiNCA() {
    const unsigned NextDFSNum(NumToNode.size());
    SmallVector<InfoRec *, 8> NumToInfo = {nullptr};
    NumToInfo.reserve(NextDFSNum);
    // Initialize IDoms to spanning tree parents.
    for (unsigned i = 1; i < NextDFSNum; ++i) {
      const NodePtr V = NumToNode[i];
      auto &VInfo = getNodeInfo(V);
      VInfo.IDom = NumToNode[VInfo.Parent];
      NumToInfo.push_back(&VInfo);
    }

    // Step #1: Calculate the semidominators of all vertices.
    SmallVector<InfoRec *, 32> EvalStack;
    for (unsigned i = NextDFSNum - 1; i >= 2; --i) {
      auto &WInfo = *NumToInfo[i];

      // Initialize the semi dominator to point to the parent node.
      WInfo.Semi = WInfo.Parent;
      for (unsigned N : WInfo.ReverseChildren) {
        unsigned SemiU = NumToInfo[eval(N, i + 1, EvalStack, NumToInfo)]->Semi;
        if (SemiU < WInfo.Semi) WInfo.Semi = SemiU;
      }
    }

    // Step #2: Explicitly define the immediate dominator of each vertex.
    //          IDom[i] = NCA(SDom[i], SpanningTreeParent(i)).
    // Note that the parents were stored in IDoms and later got invalidated
    // during path compression in Eval.
    for (unsigned i = 2; i < NextDFSNum; ++i) {
      auto &WInfo = *NumToInfo[i];
      assert(WInfo.Semi != 0);
      const unsigned SDomNum = NumToInfo[WInfo.Semi]->DFSNum;
      NodePtr WIDomCandidate = WInfo.IDom;
      while (true) {
        auto &WIDomCandidateInfo = getNodeInfo(WIDomCandidate);
        if (WIDomCandidateInfo.DFSNum <= SDomNum)
          break;
        WIDomCandidate = WIDomCandidateInfo.IDom;
      }

      WInfo.IDom = WIDomCandidate;
    }
  }
```

这个方法里做了3件事：
+ 建立DFS序数到`InfoRec`实例的映射关系，并将每个节点的直接支配节点初始化成它在生成树上的父节点，便于后续计算NCA的时候从父节点沿着支配树路径向上走。
+ 按照DFS序数倒序遍历节点，计算每个节点的半支配节点，这一步和LT算法是一模一样的。
+ 按照DFS序数正序遍历节点，对每个节点，找到它的半支配节点和它在DFS生成树上的父节点，随后用普通的暴力方式，让父节点沿着支配树上到根节点的路径往上走，走到第一个DFS序数不大于半支配节点序数的节点（因为按照DFS序数正序遍历节点，所以此时父节点的直接支配节点一定已经找到了，沿着它的直接支配节点往上走就等同于沿着支配树往上走），这个节点就是当前节点的直接支配节点。

其中第1步和第3步没有很复杂的算法设计，第2步的`eval`方法同时处理了@sdom-calculation-theorem
的$U_1$和$U_2$两种情况，可以作为非递归并查集实现的参考。

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:244~273
  unsigned eval(unsigned V, unsigned LastLinked,
                SmallVectorImpl<InfoRec *> &Stack,
                ArrayRef<InfoRec *> NumToInfo) {
    InfoRec *VInfo = NumToInfo[V];
    if (VInfo->Parent < LastLinked)
      return VInfo->Label;

    // Store ancestors except the last (root of a virtual tree) into a stack.
    assert(Stack.empty());
    do {
      Stack.push_back(VInfo);
      VInfo = NumToInfo[VInfo->Parent];
    } while (VInfo->Parent >= LastLinked);

    // Path compression. Point each vertex's Parent to the root and update its
    // Label if any of its ancestors (PInfo->Label) has a smaller Semi.
    const InfoRec *PInfo = VInfo;
    const InfoRec *PLabelInfo = NumToInfo[PInfo->Label];
    do {
      VInfo = Stack.pop_back_val();
      VInfo->Parent = PInfo->Parent;
      const InfoRec *VLabelInfo = NumToInfo[VInfo->Label];
      if (PLabelInfo->Semi < VLabelInfo->Semi)
        VInfo->Label = PInfo->Label;
      else
        PLabelInfo = VLabelInfo;
      PInfo = VInfo;
    } while (!Stack.empty());
    return VInfo->Label;
  }
```

它的逻辑为：

+ 一开始的`VInfo->Parent`的判断同时处理了节点位于$U_1$中，和位于$U_2$中但不需要路径压缩的情况。

  `LastLinked`保存了当前已经完成遍历的节点中，最后一个操作的节点的序数，如果一个节点自己的DFS序数小于`LastLinked`，那么自然它的父节点的序数也小于`LastLinked`，此时属于$U_1$的情况；如果一个节点的DFS序数大于`LastLinked`但是它的父节点的序数小于`LastLinked`，那么在此时的生成森林中，这个节点自己就是一个子树的根节点，属于$U_2$，但不需要路径压缩。

+ 如果节点需要路径压缩，那么将它到目前它所在的子树根节点（除了根节点本身）的路径保存在`Stack`中。

+ 按照出栈顺序遍历路径上的所有节点（不包括根节点本身），将它映射到的`InfoRec`结构体的`Parent`字段直接指向当前的根节点（路径上最后一个节点的父节点），并维护这个过程中遇到的半支配节点序数最小的节点，将它更新到路径上各个节点的`Label`字段中。

=== 构建支配树

在调用`attachNewSubtree`之前，`CalculateFromScratch`方法会把函数的入口基本块传入到`AttachTo`参数中。

`attachNewSubtree`方法的实现并不复杂：

```cpp
// llvm/include/llvm/Support/GenericDomTreeConstruction.h:599~616
  void attachNewSubtree(DomTreeT& DT, const TreeNodePtr AttachTo) {
    // Attach the first unreachable block to AttachTo.
    getNodeInfo(NumToNode[1]).IDom = AttachTo->getBlock();
    // Loop over all of the discovered blocks in the function...
    for (NodePtr W : llvm::drop_begin(NumToNode)) {
      if (DT.getNode(W))
        continue; // Already calculated the node before

      NodePtr ImmDom = getIDom(W);

      // Get or calculate the node for the immediate dominator.
      TreeNodePtr IDomNode = getNodeForBlock(ImmDom, DT);

      // Add a new tree node for this BasicBlock, and link it as a child of
      // IDomNode.
      DT.createNode(W, IDomNode);
    }
  }
```

它的逻辑为：

+ 对支配树的根节点，将其直接支配节点设成其自身（`AttachTo`参数对应的就是函数的入口节点，也就是支配树的根节点）。
+ 按照DFS序数正序遍历节点，对每个尚未加入到支配树的节点（根节点在遍历的循环之前已经加入了），调用`getIdom`方法，从`NodeInfo`字段中获取这个节点对应的直接支配节点的基本块，再通过这个基本块，在支配树中找到它对应的支配树节点，最后以这个支配树节点为父节点，为当前节点对应的基本块构建支配树节点。

=== 时间复杂度

时间复杂度方面，因为Semi-NCA算法的运行流程和LT算法在除了计算直接支配节点的步骤之外，其他步骤都是相同的，所以我们可以只看计算直接支配节点的求解NCA的步骤的时间开销。

先给出结论，根据LLVM中的暴力求解NCA实现，在具有$n$个节点的有向图中，执行NCA寻找直接支配点的步骤最坏情况下是$O(n)$的，从而整个算法的最坏时间复杂度为$O(n^2)$。

下面给出一个能让Semi-NCA算法得到$O(n^2)$的有向图示例，这个图也被称为`sncaworst(k)`，其中$k$是可变参数。

设$G = (V, E, s)$满足：
$
  V = {s, x_1, x_2, dots, x_k, y_1, y_2, dots, y_k} \
  (s, x_1) in E \
  forall 1 <= i < k, (x_i, x_(i + 1)) in E \
  forall 1 <= i <= k, (r, y_i) in E \
  forall 1 <= i <= k, (x_k, y_i) in E
$

可知$n = 2k + 1$，图示见下。

#diagram(
  node((0, 0), $s$, stroke: 1pt, name: <2_s>),
  node((-2, 1), $x_1$, shape: circle, stroke: 1pt, name: <2_x1>),
  node((-1, 1), $y_1$, shape: circle, stroke: 1pt, name: <2_y1>),
  node((0, 1), $y_2$, shape: circle, stroke: 1pt, name: <2_y2>),
  node((1, 1), $dots$),
  node((2, 1), $y_k$, shape: circle, stroke: 1pt, name: <2_yk>),
  node((-2, 2), $x_2$, shape: circle, stroke: 1pt, name: <2_x2>),
  node((-1, 2), $x_3$, shape: circle, stroke: 1pt, name: <2_x3>),
  node((0, 2), $dots$, name: <2_dots2>),
  node((1, 2), $x_k$, shape: circle, stroke: 1pt, name: <2_xk>),
  edge(<2_s>, <2_x1>, "->"),
  edge(<2_s>, <2_y1>, "->"),
  edge(<2_s>, <2_y2>, "->"),
  edge(<2_s>, <2_yk>, "->"),
  edge(<2_x1>, <2_x2>, "->"),
  edge(<2_x2>, <2_x3>, "->"),
  edge(<2_x2>, <2_x3>, "->"),
  edge(<2_x3>, <2_dots2>, "->"),
  edge(<2_dots2>, <2_xk>, "->"),
  edge(<2_xk>, <2_y1>, "->"),
  edge(<2_xk>, <2_y2>, "->"),
  edge(<2_xk>, <2_yk>, "->"),
  alt: "sncaworst(k)",
)

假设DFS顺序为$s, x_1, x_2, dots, x_k, y_1, y_2, dots, y_k$，那么可以看出：
$ forall 1 <= i <= k, "sdom"(y_i) = "idom"(y_i) = s, "parent"_T (y_i) = x_k $

同时有：
$
  "idom"(x_1) = s \
  forall 2 <= i <= k, "idom"(x_i) = x_(i - 1)
$

从而，对于任意$i <= i <= k$，为$y_i$从$"parent"_T (y_i) = x_k$开始往上找直接支配节点时，不得不沿着$x_k$所在的支配树链上往上走$k = O(n)$步，而一共有$k$个这样的节点，所以此时整体的NCA查找步数达到了$k^2 = O(n^2)$。

所以，LLVM选用Semi-NCA作为标准的支配树构建算法，本质上还是工业界需求的可维护性以及数据结构复杂性与实际计算效率的tradeoff，同时，在正常程序的控制流图结构中，也并不容易形成`sncaworst(k)`这样的结构。

= 参考文献或文档

+ Tanuj
  Khattar的博客：https://tanujkhattar.wordpress.com/2016/01/11/dominator-tree-of-a-directed-graph/
+ OI Wiki支配树算法：https://oi-wiki.org/graph/dominator-tree/
+ LT算法原论文：https://www.cs.princeton.edu/courses/archive/fall03/cs528/handouts/a%20fast%20algorithm%20for%20finding.pdf
