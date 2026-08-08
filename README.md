# 2026 华数杯 A 题 Q1 MATLAB 独立验证工程

本工程给出 Q1 的统一几何、电学状态和图论基础内核，兼容 MATLAB R2016a。原始附件
`data/attachment.xlsx` 只读；当前不包含 Q2、Q3、Q4。

## 运行方式

```matlab
setup_project
run('scripts/run_q1_validation.m')
```

正式输出位于 `output/Q1/`，入口会先运行全部几何、边界、Charge State 和物理图测试；
只有全部通过后才生成附件审查结果和论文图。

## Q1 基础理论与统一建模约定

### 1. 几何对象

微构体是边长 10000 nm 的立方体，坐标域为

```text
[-5000, 5000]^3 nm³
```

介质 A 是有限平端直圆柱：长度 `L_A=5000 nm`，半径 `R_A=30 nm`。两介质之间的
导通距离阈值为 `d0=1.8 nm`。

附件中的每一行永久对应一个独立 PhysicalMedium `Ai`。不同 Excel 行不能因为方向
相同、边界端点对应或 ±10000 nm 平移后吻合而共享 MediumID。

### 2. PhysicalMedium 与 GeometryPiece

Medium 是原始的 5000 nm 有限圆柱；Piece 是该 Medium 经边界处理后在当前盒内的几何
表示。一根 Medium 可以产生多个 Piece，例如：

```text
A1
├── A1-1
├── A1-2
└── A1-3
```

同一 Medium 的 Piece 保留相同 `MediumID` 和不同 `PieceIndex`。工程同时保存：

- `MediumID`、`PieceIndex`、`SourceExcelRow`
- `OriginalStart`、`OriginalEnd`
- `PieceStart`、`PieceEnd`
- `PieceLength`、`Translation`、`CrossedAxisEvent`

Piece 数量不等于介质数量；最终电学图的节点是 Piece，而不是 Medium。

### 3. 六面边界规则

对原始轴段使用参数方程

```text
P(t) = P0 + t(P1-P0),  0 ≤ t ≤ 1
```

程序计算 X/Y/Z 在所有周期平面上的交点参数 `t`，排序并合并容差内相同事件。每个相邻
参数区间作为一个整体，平移整数倍 10000 nm 映射回 `[-5000,5000]^3`。同时发生 X/Y
或更多轴事件时只生成一个断点，不产生零长度 Piece。

六个面 `x/y/z=±5000` 全部参与几何截断与位置平移，但只有 `x=-5000`（LEFT）和
`x=+5000`（RIGHT）是电极。Y/Z 四个面是绝缘边界，不直接使介质带电。

由于 `L_A=5000 < 10000`，一根介质在每个坐标轴上最多跨一个周期边界。因此最多有
三个不同参数的边界事件，即最多形成四个 GeometryPieces。1/2/3/4 Piece 以及同时
多轴事件均有 MATLAB R2016a 单元测试。

### 4. Charge State 与 Conductive Connectivity

带电状态与导通关系属于两个不同层次：

```text
Charged != Connected
```

若某个 Medium 的任一 Piece 接触 LEFT/RIGHT，或通过真实 Piece-Piece 几何边被已带电
介质激活，则该 Medium 标记为 Charged；同一 Medium 的其它 Piece 可以继承 Charged
状态。但是这种继承只改变状态标签，绝不执行 `addEdge`、`union` 或修改物理邻接表：

```text
same MediumID  => 可以共享 Charged State
same MediumID  != Conductive Edge
```

例如：

```text
LEFT
  |
A1-1

A1-2
  |
 A2
  |
 A3
  |
A1-3
  |
RIGHT
```

即使 A1-1、A1-2、A1-3 因为属于 A1 而全部带电，LEFT 到 RIGHT 也只有在
`A1-1 -> A2`、`A2 -> A3`、`A3 -> A1-3` 都存在真实有限圆柱接触边时才导通。
任一中间边缺失，结果仍是 `NON_CONDUCTING`。

代码中 `buildPieceConductGraph.m` 只构建真实物理图；`computeChargeState.m` 读取该图并
独立传播状态，不返回也不修改任何新增邻接边。

### 5. 几何导通判据

Piece-Piece 判定分两级：

1. Broad phase：计算两有限轴线段最短距离 `d_axis`。由于 `2R_A+d0=61.8 nm`，若
   `d_axis>61.8 nm`，直接排除。
2. Exact phase：其余候选使用 GJK 计算两个实体有限平端圆柱的真实表面距离
   `d_exact`；仅当 `d_exact<=1.8 nm` 才建立物理边。

`d_axis-60` 只对应旧 capsule approximation。它把圆柱端部错误替换为半球，不能作为
最终导通判据。附件 Group3 A208/A225 的实测例子中，capsule 距离为 0，而有限圆柱
GJK 距离约为 11.9 nm，故 capsule 会产生假导通边。

Piece 与电极的接触使用有限圆柱在 x 方向的精确支撑范围判断；Y/Z 面不进入电极接触
数组。不同 Medium 之间始终使用当前盒内的欧氏几何，禁止 minimum-image distance，
也禁止枚举全局 `[-10000,0,10000]^3` 镜像。

### 6. Piece-level 图论定义

正式物理图为 `G=(V,E)`：

- 节点：`LEFT`、`RIGHT` 和所有唯一重构的 `Ai-j`。
- 边：真实 Piece-Piece GJK 几何边、LEFT-Piece 接触边和 Piece-RIGHT 接触边。

Q1 使用 BFS 判断 LEFT 与 RIGHT 是否连通，并保留可解释路径。后续 Q2 若进行大量
Monte Carlo，可在不改变边定义的前提下用 DSU 优化连通性查询。

最终导通必须存在完整真实路径：

```text
LEFT -> Piece -> Piece -> ... -> RIGHT
```

所有 Piece 都 Charged 不能替代上述路径。

### 7. 统一附件重构

工程只保留两个解释层次：

- `RAW_BASELINE`：原始坐标与轴长 sanity check，不作为固定 5000 nm 模型的最终结论。
- `RECONSTRUCTED`：正式一行一 Medium 重构。

`reconstructObservedMedium.m` 是唯一正式重构器。它保留完整的
`[kx,ky,kz]∈{-1,0,1}³` 端点解卷能力，并对短 Piece 使用有限边界事件候选。若当前
Piece 长度为 `Lraw`，在前后恢复 `a,b`，满足 `a+b=5000-Lraw`；算法使用边界事件点
及事件区间代表，不连续扫描 `a`。每个 Piece 候选必须经 `wrapSegmentToBox` 正向验证。

状态只有：

- `UNIQUE`：唯一有效原始圆柱，可以生成正式 Pieces。
- `AMBIGUOUS`：多个有效原始圆柱，不强行选择。
- `UNRESOLVED`：无有效候选，不选择“最近”候选。

只要一组中存在 `AMBIGUOUS` 或 `UNRESOLVED`，该组固定 5000 nm 模型的 Q1 状态就是
`UNRESOLVED_MODEL`，它不等价于 `NON_CONDUCTING`。

## 当前附件的实际结果

### 重构状态

| Group | Records | Unique | Ambiguous | Unresolved | Q1 状态 |
|---|---:|---:|---:|---:|---|
| 1 | 12 | 9 | 0 | 3 | UNRESOLVED_MODEL |
| 2 | 49 | 33 | 0 | 16 | UNRESOLVED_MODEL |
| 3 | 535 | 505 | 30 | 0 | UNRESOLVED_MODEL |

### 唯一重构 Medium 的 Piece 数量

未解析和多解 Medium 不进入下表的正式 Piece 统计。

| Group | 1 Piece | 2 Pieces | 3 Pieces | 4 Pieces | Unique Mediums | Total Pieces |
|---|---:|---:|---:|---:|---:|---:|
| 1 | 2 | 7 | 0 | 0 | 9 | 16 |
| 2 | 11 | 22 | 0 | 0 | 33 | 55 |
| 3 | 155 | 292 | 56 | 2 | 505 | 915 |

Group3 实际存在三次截断形成的四 Piece 介质。边界轴序列由相邻 Piece 的 Translation
变化自动提取，不依赖硬编码标签。

当前三组都不能给出固定 5000 nm 介质模型的最终布尔导通答案。输出中的物理图和 Charge
State 是对唯一重构子集的诊断；网络图标题明确标记 `DIAGNOSTIC / UNRESOLVED_MODEL`。

## 正式输出

`output/Q1/tables/`：

- `medium_reconstruction.csv`：每个 Medium 的状态、候选数和 PieceCount。
- `reconstructed_pieces.csv`：唯一重构的全部 Piece 几何与边界事件。
- `piece_count_audit.csv`：Piece 数、事件序列、电极接触与带电数量审查。
- `charge_state_audit.csv`：Direct、Geometry activation、Same-Medium inheritance 分层。
- `physical_edges.csv`：唯一真实 Piece/电极物理边及距离。
- `q1_results.csv`：三组重构完整性和当前 Q1 状态。

`output/Q1/figures/`：

- `boundary_piece_examples.png`：2/3/4 Piece 参数化边界处理。
- `charge_vs_conduction.png`：Charged State 与 Conductive Edge 的区别。
- `capsule_vs_gjk_example.png`：capsule 假阳性与有限圆柱精确距离。
- `reconstruction_status.png`：三组 Unique/Ambiguous/Unresolved。
- `q1_group*_piece_network.png`：唯一重构子集的诊断物理图。

测试总表为 `output/Q1/logs/q1_test_results.txt`，摘要为
`output/Q1/q1_summary.txt`。

## 已排除的错误模型

1. 不同 Excel 行跨行合并为 Parent：废弃。
2. 不同 Medium 使用全局周期镜像或 minimum image：禁止。
3. same MediumID 自动建立隐藏导线或直接 union：禁止。
4. capsule approximation 作为最终距离：废弃。
5. 对未解析数据强行选择最近候选：禁止。
6. 把 Charged State 当作 Conductive Edge：禁止。

## 历史模型与废弃方案

- V0 曾使用 DirectionFamily 和跨行 boundary pair，违反一行一介质原则，已删除。
- V1 曾合并不同 Excel 行为 Parent，已废弃并删除历史输出。
- V2/R3 确立了一行一 Medium、Piece-level 图和参数化多边界重构。
- Current 将这些有效原则合并为非版本化的统一 Q1 基础内核。

详细开发过程由 Git commit history 保留。
