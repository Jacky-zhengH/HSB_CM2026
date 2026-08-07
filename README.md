# 2026 华数杯 A 题 Q1 MATLAB 独立验证工程

## 环境与运行

- MATLAB R2016a（9.0.0.341360）
- Windows
- 原始数据：`data/attachment.xlsx`
- 原始数据只读，程序不会修改附件。

在工程根目录执行：

```matlab
setup_project
run('scripts/run_data_audit.m')
run('scripts/run_v1_q1_validation.m')
run('scripts/run_v11_paper_polish.m')
```

`run_data_audit.m` 是 V0 唯一入口；`run_v1_q1_validation.m` 是 V1 唯一入口。
V1 输出全部位于 `output/V1/`，不会覆盖 V0 的原始输出。

## 核心数据概念

- **GeometryPiece**：附件 Excel 中的一条有限轴段记录。
- **PhysicalMedium**：一个真正的介质 A，可拥有一个或多个 GeometryPiece。
- V1 图论节点是 PhysicalMedium，不是 GeometryPiece。

## V0 数据审查结果

### 目的与读取方式

V0 用于确认附件的真实组织形式，不合并记录、不判断导通。程序先用 `xlsfinfo`
取得真实工作表“组1、组2、组3”，再用 `xlsread` 自动识别六列有限坐标，保留
`RecordID` 和 `OriginalExcelRow`，实际通过 12/49/535 条记录硬校验。

### 诊断量

- `SegmentLength` 是每条 GeometryPiece 的有限轴段长度。
- `DirectionFamily` 将方向相同或高度一致的规范化轴向归为一族；它本身不表示
  这些记录已经属于同一个 PhysicalMedium。
- `Boundary Pair Candidate` 依据“方向一致 + 端点位于相对边界 + 对一个端点施加
  ±10000 nm 平移后匹配”得到，是高可信候选关系，但不是正式 ParentID。

| 组别 | Records | Full-length | Short | DirectionFamilies | Boundary Pair Candidates |
|---|---:|---:|---:|---:|---:|
| Group 1 | 12 | 2 | 10 | 7 | 3 |
| Group 2 | 49 | 11 | 38 | 28 | 10 |
| Group 3 | 535 | 155 | 380 | 354 | 178 |

Group 3 的端点边界接触数为 XMin 91、XMax 90、YMin 61、YMax 57、ZMin 51、
ZMax 60。

### 当前解释与限制

V0 还没有直接重构 PhysicalMedium，也没有给每条 Record 正式生成 ParentID。
`SegmentLength < 5000` 只能说明该记录可能受到边界处理影响，不能单独证明它一定
属于越界介质。V0 不补长轴段、不擅自合并记录，也不输出导通结论。

## 与 Python 正式求解程序的当前差异

当前 Python `solve.py` 在 Q1 中直接读取每一行附件记录，没有先做 Parent
Reconstruction；其距离算法当前对任意不同介质使用 ±10000 周期镜像。MATLAB V1
不采用全局周期镜像，而通过显式 `GeometryPiece -> PhysicalMedium` Parent 映射表达
边界关系。这里仅记录两种模型实现差异，不预先认定哪种附件解释唯一正确。

## V1 方法

V1 同时保留三种敏感性模型：

- M0：每条 Record 独立，`ParentID = RecordID`。
- M1：仅使用 V0 `boundary_pair_candidates.csv` 的候选边，通过并查集合并 Parent。
- M2：同一 DirectionFamily 暂归为同一 Parent；这是积极的敏感性模型，不是唯一解释。

GeometryPiece 对先用有限线段距离和 61.8 nm 阈值做 broad phase，再用有限平端圆柱
support mapping 与 GJK 求真实表面距离。算法没有把圆柱实现成 capsule，也没有创建
任何全局周期几何镜像。左右电极仅为 `x=-5000` 和 `x=+5000`，导通图使用邻接表和
手写 BFS。

## V1 实际结果

MATLAB R2016a 已完成端到端运行。有限线段 5 项测试和 GJK 5 项测试全部通过；其中
共轴平端间距 50 nm 的测试返回 50 nm，避免了 capsule 的假重叠。

| 组别 | M0 Parents | M1 Parents | M2 Parents | M0 导通 | M1 导通 | M2 导通 |
|---|---:|---:|---:|---|---|---|
| Group 1 | 12 | 9 | 7 | 否 | 是 | 是 |
| Group 2 | 49 | 39 | 28 | 是 | 是 | 是 |
| Group 3 | 535 | 357 | 354 | 是 | 是 | 是 |

M1 的代表 BFS 路径为：

- Group 1：`LEFT -> P1 -> RIGHT`
- Group 2：`LEFT -> P1 -> RIGHT`
- Group 3：`LEFT -> P2 -> RIGHT`

M0 中 Group 2 的路径为 `LEFT -> P2 -> P12 -> P24 -> P39 -> RIGHT`；Group 3
的路径为 `LEFT -> P63 -> P264 -> P216 -> P351 -> RIGHT`。M1/M2 三组均存在一个
Parent 同时连接 LEFT 和 RIGHT。

DirectionFamily 总轴长接近 5000 nm 的族数分别为 5/7、24/28、305/354。程序只记录
其完整性，不对不等于 5000 nm 的 family 人工补长。

Capsule 与 GJK 产生 3 条“模型-几何对”判断分歧，对应 1 个唯一 GeometryPiece 对：
Group 3 的 Piece 208/225。其轴距约 49.4488 nm，capsule 距离约 -10.5512 nm，有限
平端圆柱 GJK 距离约 11.9342 nm，因此 capsule 判断导通而精确模型判断不导通。
该差异没有改变本次九个模型的最终导通布尔结果。

当前仍不能仅凭敏感性结果确定 M0、M1、M2 中哪一种是附件唯一正确的物理解释；
尤其 M2 的同方向合并是假设上界，M1 也只采用 V0 可识别的相对边界端点关系。

## V1.1 论文素材收尾

V1.1 不修改核心数学模型、Parent 重构、GJK 距离或导通结论。论文正文暂采用 M1
作为主模型，M2 作为边界解释敏感性分析；M0 的三组结论为 F/T/T，M1 和 M2 均为
T/T/T。

Group 1 的 M1 三维图不再使用 BFS 邻接顺序默认得到的 P1，而在所有同时连接 LEFT
和 RIGHT 的 DirectParent 中选择 `TotalAxisLength` 最接近 5000 nm 的 Parent。实际
选择为 P3，包含 Record 3、9，总轴长为 5000 nm；图中已标注 ParentID、RecordIDs
和 TotalAxisLength。

边界重构示例图增加了中文图例、RecordID、实际 Translation Vector 和周期平移箭头。
新增 `capsule_vs_gjk_example.png`，对唯一实际误判 GeometryPiece 对 Group 3 Piece
208/225 同时展示全局几何和最近区域放大图：AxisDistance 约 49.448786 nm，
CapsuleDistance 约 -10.551214 nm，ExactDistance 约 11.934211 nm，大于 1.8 nm
阈值。因此 Capsule 是 False Positive，真实有限平端圆柱不导通。唯一误判是指 1 个
GeometryPiece 对；它在 M0/M1/M2 比较表中对应 3 条模型记录。

Group 3 中 V0 的 XMin 端点接触为 91 条，而 V1 的有限圆柱 LEFT 接触为 92 条。额外
介质是 Record 92：轴端点到左平面的距离约 4.081611 nm，圆柱半径在 x 方向的投影约
29.228900 nm，有限圆柱实体到平面的距离为 0 nm。差异来自 30 nm 有限半径，而不是
新增了一个位于 `x=-5000` 的轴端点。完整数值保存在
`output/V1/logs/electrode_contact_difference.txt`。

## 论文素材索引

- `output/segment_length_distribution.png`：V0 三组 GeometryPiece 长度分布。
- `output/V1/figures/direction_family_total_length.png`：方向族总轴长完整性。
- `output/V1/figures/parent_count_comparison.png`：Record、M1 Parent、M2 Parent 数量比较。
- `output/V1/figures/boundary_reconstruction_examples.png`：三组周期边界截断与平移示例。
- `output/V1/figures/q1_model_comparison.png`：九种组别/Parent 模型的导通敏感性矩阵。
- `output/V1/figures/q1_group1_3d.png`：Group 1 的 M1 三维导通路径。
- `output/V1/figures/q1_group2_3d.png`：Group 2 的 M1 三维导通路径。
- `output/V1/figures/q1_group3_3d.png`：Group 3 的 M1 三维导通路径。
- `output/V1/figures/capsule_vs_gjk_example.png`：Capsule 假阳性与有限圆柱 GJK 对比。
- `output/V1/tables/q1_results_for_paper.csv`：论文可直接引用的简洁结果表。
- `output/V1/q1_results.xlsx`：Summary、ParentReconstruction、ModelComparison、
  CapsuleVsGJK 四类结果的 Excel 汇总。
- `output/V1/logs/electrode_contact_difference.txt`：Group 3 第 92 个左电极接触的半径来源审查。

## 版本记录

- 2026-08-07 V0：完成附件数据审查。
- 2026-08-07 V1：完成边界重构敏感性、有限圆柱 GJK、Q1 图搜索及论文素材输出。
- 2026-08-07 V1.1：完成主模型论文路径选择、边界图注释、Capsule/GJK 假阳性图和电极接触差异审查。

当前没有实现 Q2、Q3、Q4。
