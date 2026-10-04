# 待实现清单（Implementation Memo）

> 这份文件记录**视觉层讨论中产生、但尚未落地到代码**的改动。
> 边讨论边更新。确认要做时，再从这里取出逐项实现。
> 关联：[eutide-design.md](./eutide-design.md)

---

## A. 数据模型 / 后端

- [ ] **活动效率标签：单值 → 最多两个**
  - 现状：活动（hobby）的效率类型是单值字段
  - 改为：最多 **2 个**效率标签（生产性 / 创造性 / 娱乐性 / 日常性）
  - 计量规则：记录时该段时间 **全额 100% 计入两个标签**，不分权重
  - 影响：四类统计之和可超过实际用时，属正常；每类对 24h 独立衡量
  - 来源：2026-10-01 水晶球讨论

- [ ] **情绪字段：数值 1–5 → 五种 emoji 标签**
  - `TimeEntry.mood: Int?`（现 1–5）改为五档：😊愉悦 / 😌平静 / 😐还行 / 😔低落 / 😤压力
  - 记录时间条时打情绪标签

- [ ] **效率类型迁移**
  - 旧的时间分类（生产/消耗/享受/无意识/未追踪）→ 新四类效率（生产/创造/娱乐/日常）
  - 显示名去掉"性"字：生产 / 创造 / 娱乐 / 日常（更简洁）
  - 涉及活动定义、日历时间块、复盘统计

- [ ] **奖励系统数据层**（本会话已写代码，待确认 + 验证）
  - 已写：`RewardTier.swift`、`DomainOutput`(+rewardTier/isCompleted/completedAt)、`RewardItem.swift`、`OutputService`(+setCompleted)、`RewardService.swift`、`DomainViewModel.toggleComplete()`
  - 待办：用户在 Supabase 跑 SQL（outputs 加 3 列 + reward_pool 建表）→ Mac 跑 `bash sync-xcode.sh` → 验证编译（含之前 DomainViewModel 的 import Combine 修复）

---

## B. 色彩 & 渲染引擎（UI 库核心）

- [ ] **MoodBlend 色彩引擎（SwiftUI 版）**
  - 从 [liquid-lab.html](./liquid-lab.html) 的 `blend()` + OKLab 转换函数移植
  - 确认参数：**情绪浓度 chroma = 3.2，主导偏向 dominance = 3.5**
  - 做成可复用组件 `MoodBlend(分布) → Color`，复盘水晶球 / 日历时间块 / 生命树果实共用

- [ ] **液体渲染（水晶球质感）**
  - 参考 [crystal-ball-v2.html](./crystal-ball-v2.html)
  - 四层：深度饱和渐变（depth 0.55）+ 波动水面（wave 0.5）+ 高光 specular + 气泡
  - 透明度 alpha ≈ 0.82
  - 玻璃外壳：iOS 26+ 用原生 `.glassEffect()`；更老系统手搓渐变+模糊

- [ ] **Design tokens 固化**（eutide-design.md 第十五节全局改造清单）
  - 背景 #F3F1EA、强调橄榄绿 #7A9B6E、四效率莫兰迪色、陶土红 #BC6A5A
  - 情绪五色、奖励层级四色
  - 圆角 16/12px、显示字体 Baloo 2/Quicksand、文字色三档

---

## C. 页面

- [ ] **复盘页重做**
  - 远景：**四颗等大独立水晶球**（生产 · 日常 · 创造 · 娱乐），均匀一排。满球=24h，水位=用时/24，水色=该类主导情绪（MoodBlend）。颜色编码情绪、位置+标签编码类别。放弃了"两球双腔 + 刚需/消遣分组"（同腔相近情绪色难分辨）
  - 近景：点击某球展开情绪堆叠条（暖色情绪在前，尾部浅灰=没标情绪）
  - **复盘报告全程不出现 emoji**：图例色点+名字+时长，建议语纯文字
  - 奖励模块：未兑换奖励 + 奖池
  - 移除/重做"vs 4周均值"对比图（below-average 显示红色，违反「鼓励优先」）
  - 满球刻度随时间粒度调整（日=24h，周/月/季/年另定）
  - 参考实现：[crystal-ball-v4.html](./crystal-ball-v4.html)

- [ ] **生命树：产出目标改为可勾选 todo**
  - checkbox 样式 + 奖励层级（小/中/大/特大）
  - 勾选完成 → 进复盘「未兑换奖励」

- [ ] **生命树：时间粒度选择器** 周/月/季/年（周为默认）

---

## D. 功能（已讨论，未动手）

- [ ] **导出报告**
  - 周/月/季/年报告，含每个活动的情绪+用时+note
  - 格式：Markdown（优先，直接喂 Claude）、CSV、PDF
  - 入口：复盘页导出按钮 → 选周期 → 选格式 → 系统分享表单

---

## E. 工程重命名（Mac 侧 · 延后）

品牌已更名 Annuli → **Eutide**。仓库侧已全部改好（源码文件夹 `EutideSwift/`、同步脚本读取路径、设计包、文档）。剩下只在 Mac 本地 Xcode 工程里的"内部名"仍是 Annuli，可延后：

- [ ] Xcode 工程文件夹 `Annuli/` → `Eutide/`、`Annuli.xcodeproj` → `Eutide.xcodeproj`
- [ ] target / scheme / bundle id（`com.cjspark.annuli` → `.eutide`；本 app 未上架，改 bundle 无代价）
- [ ] `@main struct AnnuliApp`（`AnnuliApp.swift` → `EutideApp.swift`）、`Date+Annuli.swift` 等代码标识符
- [ ] 同步改 `sync-xcode.sh` 的 `XCODE_SRC`/`XCODE_PROJ` 与 `add-to-xcode.rb` 第 67 行 group 名 `'Annuli'` → `'Eutide'`
- [ ] App 显示名设为 Eutide（target → General → Display Name，这步最简单，可单独先做）

> 顺序：先在 Mac/Xcode 改工程名，再同步改上面两个脚本里的 `Annuli`，否则 `bash sync-xcode.sh` 会找不到工程而报错。

---

## 已定稿的关键参数（速查）

| 项 | 值 |
|---|---|
| MoodBlend 情绪浓度 chroma | 3.2 |
| MoodBlend 主导偏向 dominance | 3.5 |
| 液体 depth / alpha / wave | 0.55 / 0.82 / 0.5 |
| 满球刻度（日） | 24h |
| 活动效率标签上限 | 2 个，各 100% |
| 情绪五档 | 😊愉悦 😌平静 😐还行 😔低落 😤压力 |
| 奖励四级 | 🌱小确幸 🌟好好犒劳 🎯认真奖励 🏆里程碑 |
