#import "/template.typ": calver, post

#show: post.with(
  slug: "llvm-misc",
  title: "LLVM杂项知识",
  course: "LLVM",
  create: calver(2026, 9, 4),
  description: "这里整理一些暂时不能被完整归类到特定知识点的LLVM知识点集合。",
  tags: ("llvm", "compiler"),
  draft: false,
)

// Write the post body below.

= User

在LLVM中，每个带有值的结构（继承了`Value`的类，如Instruction，function，argument，constant等），都带有一个User列表用于查找它的值的所有使用者，通常使用`Value->users()`获取这些结构的所有使用者。可以认为User一定是一个Instruction。

== Droppable User

顾名思义，Droppable
User就是一个Value对应的即使被丢弃也不会影响程序语义的Instruction。

这里引用`User::isDroppable`方法的注释：

```cpp
// llvm/include/llvm/IR/User.h:246~249
  /// A droppable user is a user for which uses can be dropped without affecting
  /// correctness and should be dropped rather than preventing a transformation
  /// from happening.
  LLVM_ABI bool isDroppable() const;
```

`User::isDroppable`方法对droppable指令的定义非常清楚：

```cpp
// llvm/lib/IR/User.cpp:119~131
bool User::isDroppable() const {
  if (auto *II = dyn_cast<IntrinsicInst>(this)) {
    switch (II->getIntrinsicID()) {
    default:
      return false;
    case Intrinsic::assume:
    case Intrinsic::pseudoprobe:
    case Intrinsic::experimental_noalias_scope_decl:
      return true;
    }
  }
  return false;
}
```

即，仅有以下几条指令属于droppable的指令：

- `llvm.assume`
- `llvm.pseudoprobe`
- `llvm.experimental.noalias.scope.decl`

= Intrinsic函数

Intrinsic函数是指LLVM IR内置的常用函数，它们有以下特征：

+ 名字以`llvm.`开头。
+ 在LLVM IR中一定是外部函数，用`external`标记，不能对它们进行定义。
+ 在LLVM IR中可以像使用正常函数一样使用它们。

在C++中，可以使用`Function::isIntrinsic`来判断一个函数是否是Intrinsic函数。

Intrinsic函数有以下功能：
+ 提供平台无关的常用操作（`llvm.memcpy`、`llvm.abs`等）
+ 提供调试信息（`llvm.dbg.value`等）
+ 提供优化信息（`llvm.lifetime.*`、`llvm.assume`等）
