# 2026 华数杯 A 题 Q1 MATLAB 独立验证工程

## 环境与运行

- MATLAB R2016a（9.0.0.341360），Windows。
- 原始附件：`data/attachment.xlsx`，程序只读，不修改原文件。
- 当前正式入口：

```matlab
setup_project
run('scripts/run_v2_q1_rebuild.m')
```

V2 输出统一位于 `output/Q1_rebuild/`。`run_data_audit.m` 仅保留为 V0 历史数据
诊断入口，其中 DirectionFamily 和跨行 Boundary Pair Candidate 均标记为
`LEGACY_DIAGNOSTIC_ONLY`，不参与当前 Q1 求解。

## Q1 模型修正：一行一介质原则

题目规定介质 A 是高度固定为 5000 nm、半径为 30 nm 的有限平端直圆柱；附件说明
明确写明“每一行表示一个介质 A”。因此 Excel 第 i 行永久对应独立介质 `Ai`，不同
Excel 行绝不共享 MediumID，也不再允许通过方向相同、相对边界端点匹配或 ±10000 nm
平移把多行合并为一个 Parent。

一根 `Ai` 经边界规则可在盒内表现为 `Ai-1`、`Ai-2` 等多个 GeometryPiece。电学图
节点是 GeometryPiece，不是 Medium/Parent。即使两个 Piece 同属 `Ai`，也不会自动
建立隐藏导线；只有当前欧氏空间中的真实有限圆柱距离不超过 1.8 nm 才建边。只有
`x=-5000` 和 `x=+5000` 是电极，Y/Z 四个面只参与几何边界处理。

## V1 旧模型为何废弃

旧 V1 曾根据跨行边界匹配和 DirectionFamily 把不同 Excel 行合并为一个
PhysicalMedium，并把同一 Parent 的多个片段当作一个电学节点。重新审查题目后，
该假设与“一行表示一个介质 A”直接冲突，也可能产生横跨计算域的隐藏电学连接。

因此旧 M1/M2 Parent 模型及其 T/T/T 结论已废弃，不用于论文最终结论；相关主动
求解代码和 Parent 导通论文图已删除。Git 历史仍可追溯旧版本。

## 当前四种数据解释

### R0：Raw Record Baseline

直接把附件 P1→P2 当作轴段，不恢复边界编码。R0 可以完整运行，但大量轴长小于
5000 nm，与固定尺寸矛盾，因此只作为说明“必须解释附件编码”的基线/反例模型。

### R1：同一行端点周期反变换

固定 P1，仅枚举 `P2 + 10000*[kx,ky,kz]`，其中各 k 分量属于 `{-1,0,1}`。只接受
长度在固定容差内等于 5000 nm 的候选；没有候选时绝不选择“最接近”的平移。

### R2：同一行一般边界重构

对短记录分别尝试沿当前轴向在 P2 之后补齐、或在 P1 之前补齐至 5000 nm。每个候选
必须经过参数化正向周期边界处理，并重新生成附件中的当前片段才有效。两个候选都有效
时标为 `AMBIGUOUS`，都无效时标为 `UNRESOLVED`；不借用其他行补信息。

`wrapSegmentToBox.m` 通过参数 `P(t)` 求所有 X/Y/Z 周期边界交点，再按各参数区间的
中点确定整数格平移，支持单轴、双轴及连续多方向越界，不使用端点硬裁剪。

### R3：Multi-boundary Same-row Reconstruction

R3 允许附件当前行是原始 5000 nm 圆柱的中间 GeometryPiece。若当前段长为 `Lraw`，
沿当前方向在前后分别恢复 `a`、`b`，并严格满足 `a+b=5000-Lraw`。算法不连续扫描
`a`：它根据 P1/P2 是否位于 X/Y/Z 的 ±5000 边界及当前方向，计算有限个周期边界
事件，用事件点及相邻事件区间代表构造有限候选，再统一交给 `wrapSegmentToBox` 正向
验证。若同一中间 Piece 对应多个有效原圆柱，状态为 `AMBIGUOUS`，不设置选中候选。

R1 仍独立保留完整的 `[kx,ky,kz]∈{-1,0,1}^3` 共 27 组枚举；R3 没有缩减或替代
该枚举，因此端点同时发生 X/Y 多轴 ±10000 nm 平移的 R1 情形仍被覆盖。

## V2 实际数据辨识结果

### R0 原始长度

| 组别 | Records | RawLength≈5000 | RawLength<5000 |
|---|---:|---:|---:|
| Group 1 | 12 | 2 | 10 |
| Group 2 | 49 | 11 | 38 |
| Group 3 | 535 | 155 | 380 |

### R1 端点反变换

| 组别 | DIRECT_5000 | UNIQUE_ENDPOINT_UNWRAP | NO_ENDPOINT_UNWRAP | AMBIGUOUS |
|---|---:|---:|---:|---:|
| Group 1 | 2 | 0 | 10 | 0 |
| Group 2 | 11 | 0 | 38 | 0 |
| Group 3 | 155 | 0 | 380 | 0 |

实际结果说明：单纯认为某一个附件端点被 ±10000 nm 平移，不足以解释大量短记录，
R1 不能作为附件的完整解释。

### R2 同一行一般重构

| 组别 | UNIQUE_RECONSTRUCTION | UNRESOLVED | AMBIGUOUS |
|---|---:|---:|---:|
| Group 1 | 9 | 3 | 0 |
| Group 2 | 33 | 16 | 0 |
| Group 3 | 505 | 0 | 30 |

Group 1 未解析介质为 A6、A7、A11；Group 2 有 16 条未解析；Group 3 虽全部存在候选，
但其中 30 条的前延伸/后延伸假设都能正向重现附件片段，不能唯一选择。

这证明在“一行一介质”的约束下，仅由附件两个端点仍不足以唯一恢复全部 5000 nm
原始圆柱。这是数据解释结论，不是程序失败。

### R3 多边界同一行重构

| 组别 | UNIQUE_RECONSTRUCTION | UNRESOLVED | AMBIGUOUS |
|---|---:|---:|---:|
| Group 1 | 9 | 3 | 0 |
| Group 2 | 33 | 16 | 0 |
| Group 3 | 505 | 0 | 30 |

附件实测中 R3 与 R2 的计数相同：新增的中间 Piece 解释没有使现有未解析或多解行变成
唯一解。该结果并不否定 R3；强制构造的“先 X 后 Y”样例会生成 3 个 Piece，只提供
中间 Piece 反向恢复时得到 3 个正向验证候选，程序按要求输出 `AMBIGUOUS`。

## 当前 Q1 状态

| 组别 | R0 | R1 | R2 | R3 |
|---|---|---|---|---|
| Group 1 | NON_CONDUCTING | UNRESOLVED_MODEL | UNRESOLVED_MODEL | UNRESOLVED_MODEL |
| Group 2 | CONDUCTING | UNRESOLVED_MODEL | UNRESOLVED_MODEL | UNRESOLVED_MODEL |
| Group 3 | CONDUCTING | UNRESOLVED_MODEL | UNRESOLVED_MODEL | UNRESOLVED_MODEL |

R0 的真实 Piece-level BFS 路径为：

- Group 1：无路径。
- Group 2：`LEFT -> A2-1 -> A12-1 -> A24-1 -> A39-1 -> RIGHT`。
- Group 3：`LEFT -> A63-1 -> A264-1 -> A216-1 -> A351-1 -> RIGHT`。

R1/R2/R3 的 `UNRESOLVED_MODEL` 表示数据解释不完整，绝不等价于 `NON_CONDUCTING`，
因此当前不能把 R0 的布尔结果直接当作固定 5000 nm 介质模型的最终 Q1 答案。

## 无隐藏导线验证

`testNoHiddenParentConnection.m` 构造同属 A1 的两个 Piece：A1-1 接触 LEFT，A1-2
接触 RIGHT，但两者在盒内相距很远。测试确认两 Piece 之间没有电学边，LEFT 无法到达
RIGHT，结果为 NON_CONDUCTING。该测试已在 MATLAB R2016a 中通过。

## 附件坐标异常记录

题面边界仍固定为 ±5000 nm，不把 ±500 当边界。附件精确数值统计为：Group 1 中
±500 共 6 个、±5000 共 7 个；Group 2 中 ±500 共 24 个、±5000 共 22 个；Group 3
中 ±500 为 0、±5000 共 410 个。该特征仅作事实记录，需谨慎解释。

## 当前尚未确定的问题

附件没有说明短记录的两个端点究竟对应完整介质端点、单个截断 Piece 端点，还是其他
编码。R2/R3 已证明部分行无法重构、部分行存在多个候选。除非获得附件生成规则或额外字段，
不能在不引入额外假设的前提下唯一恢复所有 5000 nm 介质，也不能给 R1/R2/R3 强制输出
Q1 布尔答案。

## 论文素材索引

- `raw_length_distribution.png`：展示原始轴长与 5000 nm 理论值的矛盾。
- `r1_endpoint_unwrap_success.png`：说明单端点周期反变换不足以解释短记录。
- `row_reconstruction_examples.png`：展示 R1 成功、R2 补救和 R2 未解析实例。
- `r3_multiboundary_example.png`：展示先 X 后 Y 形成 3 个 Piece，以及仅凭中间 Piece
  反向恢复时的多解状态。
- `no_hidden_connection_demo.png`：解释同 MediumID 不产生隐藏电学边。
- `q1_group*_piece_network.png`：R0 可完整计算时的 Piece-level 网络和真实 BFS 路径。
- `r3_reconstruction_candidates.csv`：R3 的 `a`、`b`、原始端点和正向验证结果。
- `q1_model_results.csv`：R0/R1/R2/R3 的解析完整性与导通状态汇总。
- `capsule_vs_gjk_example.png`：保留的有限平端圆柱 GJK 与 capsule 假阳性素材。

除最后一项外，以上素材位于 `output/Q1_rebuild/figures/` 或
`output/Q1_rebuild/tables/`；最后一项保留于
`output/V1/figures/`，其几何结论不依赖旧 Parent 模型。

## 版本记录

- 2026-08-07 V0：完成附件原始数据审查。
- 2026-08-07 V1/V1.1：曾进行跨行 Parent 敏感性分析，现已废弃，不用于正式结论。
- 2026-08-08 V2-Q1：改为一行一介质、同一行重构和 Piece-level 无隐藏导线模型。
- 2026-08-08 R3：新增多边界中间 Piece 有限事件重构、正向验证和显式多解输出。

当前未实现 Q2、Q3、Q4。
