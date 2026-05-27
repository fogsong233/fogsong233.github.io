
---
title: 随机n个点落在一个半圆
tags:
---

#set text(
  font: (
    "Libertinus Serif",
    "STZhongsong",
    "STSong",
    "SimSun",
    "Noto Serif CJK SC",
    "Noto Sans CJK SC",
    "AR PL SungtiL GB",
  ),
  size: 12pt,
)
#set page(margin: (x: 2.2cm, y: 2.5cm))
#set par(justify: true, leading: 0.7em)

这个问题有很多巧妙构造的解法, 这里提供一个最朴实, 也是最泛用的,
基于连续随机变量的解法.

给出问题的严谨定义:

考虑概率密度函数
$
  f(x, y) = cases(1/pi quad x^2 + y^2 <= 1, 0 quad "otherwise")
$
有$P_1, P_2, dots, P_n$的二维随机变量的独立, 且满足这个密度函数.
求
$
  Pr(P_1, P_2, dots, P_n "在同一个半圆")
$

这个概率等价于, 考虑极坐标变换后,
$
  P_i = (X_i, Y_i) = (R_i cos Theta_i, R_i sin Theta_i),
  R_i in [0, 1], Theta_i in [0, 2pi)
$
其中角度变量$Theta_i$应该理解为模$2pi$意义下的变量.

我们要求的是: 是否存在某个长度为$pi$的圆弧, 能同时包含所有角度
$Theta_1, Theta_2, dots, Theta_n$. 也就是说, 记
$
  I(alpha) = {theta in [0, 2pi) : (theta - alpha) mod 2pi in [0, pi]}
$
那么要求的是
$
  Pr(exists alpha in [0, 2pi), forall i, Theta_i in I(alpha)).
$

为了避免圆周边界带来的麻烦, 我们下面采用一种等价的展开方式:
先固定某一种角度的循环排序. 例如, 从$Theta_1$开始沿逆时针方向展开圆周,
并考虑
$
  Theta_1 < Theta_2 < dots < Theta_n < Theta_1 + 2pi
$
意义下的展开角度. 在这个展开坐标中, 所有点落在同一个半圆内,
等价于
$
  Theta_n - Theta_1 <= pi.
$
这里的$Theta_2, dots, Theta_n$不再只是普通的$[0, 2pi)$中的数,
而是允许在以$Theta_1$为起点的展开区间
$
  [Theta_1, Theta_1 + 2pi)
$
中取值. 因此如果积分上界超过$2pi$, 它表示的是圆周上的绕回区间,
而不是普通实数角度越界.

== 概率变换

我们首先做概率密度函数的坐标系变换, 这和多元微积分的规则是一致的:
$
     & g(r, theta) dif r dif theta = f(x, y) dif x dif y \
     & dif x dif y = r dif r dif theta \
  => & g(r, theta) = r / pi
$

考虑$P_1, P_2, dots, P_n$在圆周上的循环排序.
由于角度分布是连续的, 两个点角度完全相同的概率为$0$, 所以几乎必然可以唯一排序.

我们先固定其中一种展开后的排序:
$
  Theta_1 < Theta_2 < dots < Theta_n < Theta_1 + 2pi
$
并且要求这些点落在从$Theta_1$出发、长度为$pi$的半圆中, 即
$
  Theta_n - Theta_1 <= pi.
$
记这个特定排序并满足半圆条件的概率为$R_n$.

由于$n$个点的所有标号排序共有$n!$种, 且在连续情形下边界重合的情况概率为$0$,
所以由全概率公式,
$
  Pr(exists alpha in [0, 2pi), forall i, Theta_i in I(alpha)) = n! R_n.
$
那么下面我们的重点就是$R_n$, 而且, 这个表示暗示我们下面要开始递推了.

== 递推

因为现在我们已经固定了所有点在$Theta$上的循环排序, 那我们就可以一个一个开始放点.
排序最前面的点是随机放的, 第二个点要保证
$
  Theta_2 > Theta_1
$
且
$
  Theta_2 - Theta_1 <= pi,
$
后面的点也要依次保持排序, 并且不能超过$Theta_1 + pi$.
这样全部积分起来就是这个特定排序下的概率.

#let bb = it => text(fill: blue)[#it]
#let gg = it => text(fill: green)[#it]

$
  R_1 & = integral_0^(2pi) dif theta_1 integral_0^1 g(r_1, theta_1) dif r_1 \
      & = bb(integral_0^(2pi) dif theta_1 integral_0^1 r_1 / pi dif r_1) = 1 \
  R_2 & = bb(integral_0^(2pi) dif theta_1 integral_0^1 r_1 / pi dif r_1)
        gg(integral_(theta_1)^(theta_1 + pi) dif theta_2 integral_0^1 r_2 / pi dif r_2) \
  R_3 & = bb(integral_0^(2pi) dif theta_1 integral_0^1 r_1 / pi dif r_1)
        gg(integral_(theta_1)^(theta_1 + pi) dif theta_2 integral_0^1 r_2 / pi dif r_2)
        integral_(theta_2)^(theta_1 + pi) dif theta_3 integral_0^1 r_3 / pi dif r_3 \
      & dots
$

无论从直观上, 还是从式子的比对上, 我们都能发现, 这个式子其实是一个递推.
具体地, 设
$
        Q_2(theta_1) & = integral_(theta_1)^t dif theta_2 integral_0^1 r_2 / pi dif r_2 \
  Q_(m + 1)(theta_1) & = integral_(theta_1)^t dif theta_2 integral_0^1 r_2 / pi dif r_2 Q_m(theta_2), quad m >= 2
$
这里$Q$从$Q_2$开始, 主要是方便数下标.

如果设
$
  t = theta_1 + pi,
$
那么我们有
$
  R_n = integral_0^(2pi) dif theta_1 integral_0^1 r_1 / pi dif r_1 Q_n(theta_1)
$
读者代入不难验证上式.

下面我们就着手求上面式子的递推. 事实上, 你求一下会发现$dif r$稳定产出乘以$1 / (2pi)$,
而$theta$的每次积分都会让$t - theta$的阶数高一阶, 同时产出一个阶乘因子.
因此可以通过求前三项直接猜出$Q_n$的通项:
$
  Q_(1 + k)(theta_1) = (t - theta_1)^k / (pi^k 2^k k!)
$

下面我们用数学归纳证明:

$
  k = 1, Q_(1 + k)(theta_1) & = (t - theta_1) / (2pi), "直接积分即可" \
  k = n, Q_(1 + k)(theta_1) & = (t - theta_1)^k / (pi^k 2^k k!) \
  Q_(n + 2)(theta_1) & = integral_(theta_1)^t dif theta_2 integral_0^1 r_2 / pi dif r_2 Q_(n + 1)(theta_2) \
  & = integral_(theta_1)^t dif theta_2 integral_0^1 r_2 / pi dif r_2 (t - theta_2)^n / (pi^n 2^n n!) \
  & = integral_(theta_1)^t dif theta_2 (t - theta_2)^n / (pi^(n + 1) 2^(n + 1) n!) \
  & = integral_0^(t - theta_1) u^n / (pi^(n + 1) 2^(n + 1) n!) dif u \
  & = (t - theta_1)^(n + 1) / (pi^(n + 1) 2^(n + 1) (n + 1)!) quad qed
$

那么我们一步就能得到$R_n$.
令
$
  t = theta_1 + pi,
$
那么$t - theta_1$直接变成$pi$了. 所以
$
  R_n & = integral_0^(2pi) dif theta_1 integral_0^1 r_1 / pi dif r_1 Q_n(theta_1) \
      & = integral_0^(2pi) dif theta_1 integral_0^1 r_1 / pi dif r_1
        pi^(n - 1) / (pi^(n - 1) 2^(n - 1) (n - 1)!) \
      & = integral_0^(2pi) 1 / (pi 2^n (n - 1)!) dif theta_1 \
      & = 1 / (2^(n - 1) (n - 1)!).
$

带回原来的圆周问题:
$
  Pr(exists alpha in [0, 2pi), forall i, Theta_i in I(alpha))
  = n! R_n
  = n / 2^(n - 1).
$

那么我们就非常"笨拙地"详细算出来了整个通项啦!
虽然笨拙, 但它展示了这个问题最本质的一面:
先用极坐标把二维均匀分布转化为角度问题,
再通过固定一种循环排序来写出积分区域.
