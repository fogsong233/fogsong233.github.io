---
title: PCA
date: 2026-05-26 18:27:18
tags:
  - typst
  - machine-learning
categories:
  - Machine Learning
typst_render: html
---

#import "@preview/cetz:0.5.1"
#import "@preview/suiji:0.5.1": *
#set text(font: ("Libertinus Serif", "Noto Serif CJK SC", "Noto Sans CJK SC", "AR PL SungtiL GB", "STZhongsong", "STSong", "SimSun"), size: 12pt)
#set page(margin: (x: 2.2cm, y: 2.5cm))
#set par(justify: true, leading: 0.7em)

= PCA
神经网络本质的目的是为了检查和生成来源于客观世界的信息。客观世界的信息，从一张图片到一段文字，是一个极大的数量级。考虑一张 $28 times 28$ 的纯黑白二值图片，那么整个数据的空间大小就是 $2^(28 times 28)$。如果我们能给这里面的每张图片都生成一个标签，那么我们显然可以准确无误地对所有这个尺寸的图片做判断。

但是，显然现实中我们不可能得到所有的图片数据，更不可能储存起来。我们考虑这个问题：在给定储存空间下，我们如何最好地利用储存空间，使得我们储存的数据更逼近原来的数据呢？

== 问题的形式化

#let xx = num => $arrow(x)_#[#num]$
#let bb = num => $arrow(b)_#[#num]$
#let av = num => $arrow(chi)_#[#num]$
#let zz = num => $arrow(z)_#[#num]$
#let mt = w => $upright(bold(#w))$

假设我们有 $xx(1), xx(2), dots, xx(N); xx(i) in RR^(M)$，或者说矩阵 $mt(X) in RR^(N times M)$ 的数据。我们想要得到一个子空间，其基向量为：
$
  bb(1), bb(2), dots, bb(m);
  bb(i) dot bb(j) = 0 quad (i != j);
  ||bb(i)||^2 = 1
$
也可以写成正交矩阵 $mt(B) in RR^(m times M)$。

对应的，$zz(1), zz(2), dots, zz(N) in RR^m$ 为原数据近似到这个子空间的低维坐标，同时：
$
  av(i) = mt(B)^(upright(T)) zz(i) in RR^M
$
也就是在原高维空间中近似 $xx(i)$ 的重构向量。

其中 $m << M << N$，我们只需要储存基矩阵 $mt(B)$ 和低维坐标 $zz(i) , (i = 1, 2, dots, N)$，从而大幅减少数据量。

如何衡量这个压缩的效果呢？或者说，怎么样才能让重构数据和原数据更逼近呢？

== 投影
我们先不在意基向量 $bb(i)$ 的具体选择，而是考虑在确定的 $mt(B)$ 下，$av(i)$ 和 $xx(i)$ 的关系。也就是说，如何选取一组在 $mt(B)$ 下的坐标，使得信息损失最少（两者的欧氏距离最小）？

形式化地，也就是求以下目标函数的最小值：
$
  L = 1/N sum_(i=1)^N ||xx(i) - av(i)||^2, quad av(i) = mt(B)^(upright(T)) zz(i)
$
此时的自变量是低维坐标 $zz(i)$。这里使用分母布局直接对 $zz(i)$ 求导：
$
  (partial L) / (partial zz(i)) = (partial av(i)) / (partial zz(i)) (partial L) / (partial av(i)) = 2/N mt(B) (xx(i) - av(i)) = 0
  => mt(B) xx(i) = mt(B) av(i) = mt(B) mt(B)^(upright(T)) zz(i)
$
因为 $mt(B)$ 的各行是标准正交基，故 $mt(B)mt(B)^(upright(T)) = mt(I)_m$，因此我们得到了：
$
  zz(i) = mt(B) xx(i)
$
也就是说，对特定的基矩阵 $mt(B)$，使得损失最小的办法就是**直接将原向量投影到 $mt(B)$ 支撑的子空间**。

== 角度一: 最大的多样性

#grid(columns: (1fr, 3em, 1fr), align: center + horizon)[
  #cetz.canvas(x: 2, y: 2, {
    import cetz.draw: *
    grid(
      (0, 0),
      (4, 4),
      help-lines: true,
    )
    fill(black)
    stroke(none)
    let n = 16
    let radio = 4.5
    let a = 0.6 / radio
    let b = 5 / radio
    let rng = gen-rng-f(42)
    let noise1 = ()
    let noise2 = ()
    let alpha = 0.1
    for i in range(1, n + 1) {
      (rng, noise1) = normal(rng)
      (rng, noise2) = normal(rng)
      circle((i / radio + noise1 * alpha, a * i + b + noise2 * alpha), radius: 2pt)
    }
  })
][
  $bold(arrow)$
][
  #cetz.canvas(x: 2, y: 2, {
    import cetz.draw: *
    grid(
      (0, 0),
      (4, 4),
      help-lines: true,
    )
    fill(black)
    stroke(none)
    let n = 16
    let radio = 4.5
    let a = 0.6 / radio
    let b = 5 / radio
    let rng = gen-rng-f(42)
    let noise1 = ()
    let noise2 = ()
    let alpha = 0.1
    for i in range(1, n + 1) {
      (rng, noise1) = normal(rng)
      (rng, noise2) = normal(rng)
      circle((i / radio + noise1 * alpha, a * i + b + noise2 * alpha), radius: 2pt)
    }
    let end = 18
    stroke(2pt + blue)
    line((0, b), (end / radio, end * a + b))
  })
]

假设 $M = 2, m = 1$，考虑如左图所示的数据集。显然如果我们选择 $bb(1)$ 为右图的蓝线方向来近似，能得到最好的效果。

为什么呢？我们既可以说这些点和这条线贴合得最近，也可以说所有的数据在这个子空间（也就是这条线）上投影后伸展得最开，也就是说，**展现了最大的多样性（方差最大）**。反之，如果选择和蓝线正交的方向，所有的点在投影后会紧密堆积在一起，失去原有的区分度。

为了方便计算，我们可以先假设数据已经过了中心化预处理，即均值为 0：
$ EE = 1/N sum_(i = 1)^N xx(i) = arrow(0) $

因此目前的方差等价于

$ VV_N = 1/N sum_(i=1)^N zz(i)^(upright(T)) zz(i) in RR $.

因此
$
  VV_N & = 1/N sum_(i=1)^N zz(i)^(upright(T)) zz(i)
  & = 1/N sum_(i=1)^N tr(zz(i) zz(i)^(upright(T)))
  & = 1/N sum_(i=1)^N tr(mt(B) xx(i) xx(i)^(upright(T)) mt(B)^(upright(T)))
$
因为求和和求迹都是线性算子，把求和号移进迹
$
  & = 1/N tr(mt(B) (sum^N_(i=1) xx(i) xx(i)^(upright(T))) mt(B)^(upright(T))) & = 1/N tr(mt(B) mt(S) mt(B)^(upright(T)))
$

$mt(S)$是$x$不同分量的协方差矩阵, 因此是对称的, 所以有
$
  & = 1/N tr(mt(B) mt(U) Lambda mt(U)^(upright(T)) mt(B)^(upright(T)))
$

$
  & = 1/N tr(mt(P) Lambda mt(P)^(upright(T))), quad mt(P) = mt(B)mt(U)
$
我们来检查新矩阵 $mt(P) in RR^(m times M)$ 的性质。由于 $mt(B)$ 满足正交约束 $mt(B)mt(B)^(upright(T)) = mt(I)_m$，且 $mt(U)$ 是正交阵（$mt(U)mt(U)^(upright(T)) = mt(I)_M$），因此有：
$
  mt(P) mt(P)^(upright(T)) = (mt(B) mt(U)) (mt(B) mt(U))^(upright(T)) = mt(B) mt(U) mt(U)^(upright(T)) mt(B)^(upright(T)) = mt(B) mt(I)_M mt(B)^(upright(T)) = mt(B)mt(B)^(upright(T)) = mt(I)_m
$
这说明新矩阵 $mt(P)$ 的这 $m$ 个行向量之间依然保持着标准正交的关系。

现在，我们将目标函数的矩阵迹展开为对角阵的加权求和形式：
$
  1/N tr(mt(P) Lambda mt(P)^(upright(T))) = 1/N sum_(j=1)^m sum_(k=1)^M P_(j,k)^2 lambda_k = sum_(k=1)^M (sum_(j=1)^m P_(j,k)^2) (lambda_k / N)
$
令 $w_k = sum_(j=1)^m P_(j,k)^2$ 作为分配给第 $k$ 个特征值的"权重配额"。由于 $mt(P)$ 的行向量是标准正交的，这些配额受到两个严格的边界限制：
1. 全局总配额有限：$sum_(k=1)^M w_k = m$（即矩阵 $mt(P)$ 所有元素的平方和等于其行数 $m$）。
2. 单项上限约束：由于 $mt(P)$ 的列向量可以看作$mt(U)$的一个模长为1的向量在$mt(B)$子空间的投影坐标, 因此其平方和是模长, 投影模长不可能超过原始模长1，故对任意 $k$ 均有 $0 <= w_k <= 1$。

此时，最大化总方差的问题演变成了一个经典的贪心策略问题：我们的手里一共有总和为 $m$ 的筹码，每个坑位最多只能填 1 个筹码，而每个坑位的奖励权重是降序排列的（$lambda_1 >= lambda_2 >= dots >= lambda_M >= 0$, $mt(S)$是半正定的）。

为了让最终的加权和最大，最完美的策略显然是将所有的筹码配额优先塞满奖励最高的前 $m$ 个坑位，即令：
$
  w_1 = 1, w_2 = 1, dots, w_m = 1; quad w_(m+1) = dots = w_M = 0
$
所以
$
  VV_N = sum_(k=1)^M (sum_(j=1)^m P_(j,k)^2) (lambda_k / N) <= 1/N (lambda_1 + dots + lambda_m)
$
而如果我们取$mt(B)$的行向量是这些特征值对应的特征向量, 也就是
$
  mt(S) bb(i) = lambda_i bb(i), i = 1, 2, dots, m
$

那么有
$
  mt(P) = mt(B) mt(U) = vec(bb(1), bb(2), dots, bb(m)) mat(bb(1), bb(2), dots, bb(i), dots, bb(M)) = mat(mt(I)_m, mt(0))
$
这里$bb(i)$的序数被扩大了, 表示未被选中的特征向量, 仍然按照特征值的大小排序。
这个时候就是
$
  w_1 = 1, w_2 = 1, dots, w_m = 1; quad w_(m+1) = dots = w_M = 0
$
所以这个不等号可以被取到.
这样我们就证明了最大的值在我们选择$mt(B)$的前$m$大的特征值的特征向量时取到.注意， 这个
并非唯一的解， 只要$mt(B)$的子空间是一样的就可以了。
同时，约定 $mt(X)$ 的 SVD 为 $mt(X) = mt(V) mt(Sigma) mt(U)^(upright(T))$（其中 $mt(U) in RR^(M times M)$ 为右奇异向量矩阵），则：
$
  mt(S) = mt(X)^(upright(T)) mt(X) = (mt(U) mt(Sigma) mt(V)^(upright(T)))(mt(V) mt(Sigma) mt(U)^(upright(T))) = mt(U) mt(Sigma)^2 mt(U)^(upright(T))
$
因此为了求$mt(S)$的特征值, 我们只需要对$mt(X)$做SVD即可.

== 角度二: 最小的损失
推导出PCA不只有一种角度, 在所有的角度上, 推出PCA似乎都是一种必然.
我们考虑这样的事情, 不再考虑子空间舒展的多样性, 而是考虑最小化和原向量的误差, 也就是
$
  J = sum_(i = 1)^N ||xx(i) - av(i)||^2
$
同样的, 为了方便计算，我们可以先假设数据已经过了中心化预处理，即均值为 0：
$ EE = 1/N sum_(i = 1)^N xx(i) = arrow(0) $
我们对$bb(i)$做施密特正交化的扩展， 得到
$
  bb(1), bb(2), dots, bb(M); quad
  bb(i) dot bb(j) = cases(1 quad i = j, 0 quad i != j)
$
因此我们有
$
  av(i) = sum_(j = 1)^m z_(i j) bb(j)
$
而
$
  xx(i) = sum_(j = 1)^M z_(i j) bb(j)
$
这里就是$xx(i)$变化到了$bb(j)$这个完整空间的完整坐标。因为$zz(i) = mt(B) xx(i)$，$av(i)$就是前$m$项内容在高维空间的重构，我们对$zz(i)$长度扩充的话，就是$xx(i)$的完整坐标.
因此
$
  J = sum_(i = 1)^N ||xx(i) - av(i)||^2 = sum_(i=1)^N ( sum_(j=m+1)^M z_(i j) bb(j) )^2
$
发现了吗？ 我们得到了和角度一形式上完全对偶的一个式子——只不过这里的$mt(B)$是$mt(B)'$，也就是
剩下的向量，这里的$zz(i)$是剩下的向量的项。相对的，求最大值变成了最小值。我们前面分析
了，值其实是对$lambda_i$的选择，那么为了最小化，我们选择最小的$lambda_i$.
那么这个时候，原始$mt(B)$的空间其实就是$lambda_1, lambda_2, dots, lambda_m$长成
的子空间。而这是我们可以更直观地发现，其实$mt(B)$不必然是$lambda_i$对应的特征向量，我们只需要
找到这个最大逼近的子空间就可以了！不过显然做SVD找起来最简单方便的。

== 角度三： 信息熵逼近
从信息论的角度来看，高维数据中包含的信息量可以用**信息熵（Information Entropy）**来衡量。对于多元高斯分布的数据，其熵的大小直接正比于其协方差矩阵行列式的对数。

假设高维原始数据 $xx(i) in RR^M$ 服从均值为 $arrow(0)$，协方差矩阵为 $mt(S)$ 的多元正态分布 $cal(N)(arrow(0), mt(S))$。其连续信息熵定义为：
$
  H(mt(X)) & = - EE[ln p(arrow(x))] \
  & = - EE[ln (1/((2 pi)^(M/2) det(S)^(1/2)) exp(-1/2 (arrow(x) - arrow(mu))^(upright(T)) mt(S)^(-1) (arrow(x) - arrow(mu))))] \
  & = 1/2ln((2 pi )^M det(mt(S))) + 1/2 EE[(arrow(x) - arrow(mu))^(upright(T)) mt(S)^(-1) (arrow(x) - arrow(mu))] \
  & = 1/2ln((2 pi )^M det(mt(S))) + 1/2 EE[tr((arrow(x) - arrow(mu))^(upright(T)) mt(S)^(-1) (arrow(x) - arrow(mu)))] \
  & = 1/2 ln((2 pi )^M det(mt(S))) + 1/2 EE[tr((arrow(x) - arrow(mu))(arrow(x) - arrow(mu))^(upright(T)) mt(S)^(-1))] \
  & = 1/2 ln((2 pi )^M det(mt(S))) + 1/2 EE[tr(mt(S) mt(S)^(-1))] \
  & = 1/2 ln((2 pi )^M det(mt(S))) + 1/2 M \
  &= M/2 (1 + ln(2 pi)) + 1/2 ln det(mt(S))
$
当我们将数据投影到由 $mt(B) in RR^(m times M)$ 支撑的低维子空间，得到 $zz(i) = mt(B)xx(i)$ 时，由前面的推导， 低维变量 $zz(i)$ 的协方差矩阵变为 $mt(S)_z = mt(B)mt(S)mt(B)^(upright(T))$。

此时，低维空间所保留的信息熵为：
$
  H(mt(Z)) = m/2 (1 + ln(2 pi)) + 1/2 ln det(mt(B)mt(S)mt(B)^(upright(T)))
$
为了让压缩后的低维特征最大程度地保留原始高维空间的信息（即信息流失最少），我们的目标是**最大化低维空间的熵 $H(mt(Z))$**。在基向量标准正交（$mt(B)mt(B)^(upright(T)) = mt(I)_m$）的约束下，这等价于求解：
$
  max_(mt(B)) det(mt(B)mt(S)mt(B)^(upright(T)))
  "subject to" quad mt(B)mt(B)^(upright(T)) = mt(I)_m
$

利用对称阵 $mt(S)$ 的特征值分解 $mt(S) = mt(U)Lambda mt(U)^(upright(T))$，并令 $mt(P) = mt(B)mt(U)$（满足 $mt(P)mt(P)^(upright(T)) = mt(I)_m$），目标矩阵可以写为：
$
  mt(B)mt(S)mt(B)^(upright(T)) = mt(P)Lambda mt(P)^(upright(T))
$
由 Cauchy-Binet 公式，对任意满足 $mt(P)mt(P)^(upright(T)) = mt(I)_m$ 的矩阵 $mt(P) in RR^(m times M)$ 与半正定对角阵 $Lambda$，有：
$
  det(mt(P)Lambda mt(P)^(upright(T))) = sum_(|S|=m) product_(k in S) lambda_k dot m_S^2 <= product_(i=1)^m lambda_i
$
其中求和遍历所有大小为 $m$ 的下标子集 $S$，$m_S$ 为 $mt(P)$ 对应列构成的 $m times m$ 子方阵的行列式，且由 Cauchy-Binet 公式知 $sum_(|S|=m) m_S^2 = det(mt(P)mt(P)^(upright(T))) = 1$。因此上界等号当且仅当所有权重集中在 $S = {1, dots, m}$（对应最大 $m$ 个特征值）时取到。

当且仅当 $mt(P) = mat(mt(I)_m, mt(0))$ 时，等号成立。此时 $mt(B)$ 对应的行向量恰好是 $mt(S)$ 前 $m$ 个最大特征值所对应的特征向量。

== 角度四：线性自编码器的等价性

回到文章开头的问题：神经网络能从数据中学到什么？我们来考察最简单的一种神经网络——**线性自编码器**。它由两个无激活函数的线性层组成：

$
  "encoder" quad zz(i) = mt(W)_e xx(i), quad mt(W)_e in RR^(m times M)
$
$
  "decoder" quad av(i) = mt(W)_d zz(i) = mt(W)_d mt(W)_e xx(i), quad mt(W)_d in RR^(M times m)
$

训练目标是最小化重构误差：
$
  L(mt(W)_e, mt(W)_d) = 1/N sum_(i=1)^N ||xx(i) - mt(W)_d mt(W)_e xx(i)||^2
$

与PCA的角度二对比，这个损失函数的形式完全相同，区别仅在于**约束条件**：PCA要求 $mt(B)mt(B)^(upright(T)) = mt(I)_m$，而线性自编码器对 $mt(W)_e$ 和 $mt(W)_d$ 没有任何正交约束。

这看起来是一个更宽松的问题——那么它的解还是PCA吗？

=== 参数空间的等价重构

令 $mt(A) = mt(W)_d mt(W)_e in RR^(M times M)$，注意到：
$
  "rank"(mt(A)) = "rank"(mt(W)_d mt(W)_e) <= min("rank"(mt(W)_d), "rank"(mt(W)_e)) <= m
$

反过来，任意一个秩不超过 $m$ 的矩阵 $mt(A) in RR^(M times M)$ 都可以通过秩分解写成 $mt(A) = mt(W)_d mt(W)_e$ 的形式。因此，对 $(mt(W)_e, mt(W)_d)$ 的联合优化，与直接对所有秩不超过 $m$ 的矩阵 $mt(A)$ 优化，是完全等价的：

$
  min_(mt(W)_e, mt(W)_d) L(mt(W)_e, mt(W)_d) = min_(mt(A),\ "rank"(mt(A)) <= m) 1/N sum_(i=1)^N ||(mt(I) - mt(A))xx(i)||^2
$

右边的问题正是角度二中的最小重构误差问题，只不过去掉了正交性约束，允许 $mt(A)$ 是任意秩为 $m$ 的矩阵（而不仅仅是正交投影）。


然而，从角度二的推导中我们已经知道：对任意固定子空间，使重构误差最小的映射恰好是**正交投影**。换句话说，即使允许 $mt(A)$ 是任意秩-$m$ 矩阵，最优的 $mt(A)^*$ 也必然是某个 $m$ 维子空间上的正交投影算子：
$
  mt(A)^* = mt(U)_m mt(U)_m^(upright(T))
$
其中 $mt(U)_m$ 的列为 $mt(S)$ 前 $m$ 个最大特征值对应的特征向量。这与角度二的结论完全吻合——PCA 子空间是全局最优解。

一组具体的最优参数为 $mt(W)_d = mt(U)_m,\ mt(W)_e = mt(U)_m^(upright(T))$，但最优解并不唯一：对任意 $m times m$ 正交矩阵 $mt(R)$，令
$
  mt(W)_d = mt(U)_m mt(R), quad mt(W)_e = mt(R)^(upright(T)) mt(U)_m^(upright(T))
$
同样满足 $mt(W)_d mt(W)_e = mt(U)_m mt(U)_m^(upright(T))$，因此也是全局最优解。这说明线性自编码器的权重矩阵本身存在**旋转自由度**：网络学到的编码和解码方向在子空间内可以任意旋转，但它们共同张成的子空间始终是唯一确定的 PCA 主成分子空间。


一个没有任何正交约束、通过梯度下降训练的线性神经网络，在全局最优时自然地发现了数据中最重要的线性结构。一方面， 他说明了神经网络真正的能够总结规律， 另一方面， 也说明
了PCA就是提炼规律的最佳结果。


= 总结

我们从四个完全不同的角度出发，推导出了同一个结论：

#table(
  columns: (auto, 1fr, 1fr),
  inset: 8pt,
  align: (center, left, center),
  stroke: 0.5pt,
  [*角度*], [*优化目标*], [*最优解*],
  [最大多样性], [最大化投影方差 $"tr"(mt(B)mt(S)mt(B)^(upright(T)))$], [前 $m$ 大特征向量],
  [最小损失], [最小化重构误差 $sum||xx(i) - av(i)||^2$], [前 $m$ 大特征向量],
  [信息熵], [最大化低维熵 $det(mt(B)mt(S)mt(B)^(upright(T)))$], [前 $m$ 大特征向量],
  [自编码器], [最小化重构误差，无正交约束], [前 $m$ 大特征向量],
)

PCA 主成分子空间作为数据线性结构的某种**本质最优性**：它同时是方差最集中的方向、信息损失最少的方向、高斯假设下信息量最大的方向，也是无约束线性模型自然收敛的方向。(这里站不下这么多人x)

PCA 是线性降维的起点。当数据的有效结构是非线性流形时，线性子空间的假设就会失效-这就是后话了。
