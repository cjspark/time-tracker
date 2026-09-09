# Annuli — 原生 SwiftUI 版本

## 在 Mac 上设置 Xcode 项目（5步）

### 第 1 步：新建 Xcode 项目

1. 打开 Xcode → **File → New → Project**
2. 选择 **iOS → App**
3. 填写：
   - **Product Name**: `Annuli`
   - **Bundle Identifier**: `com.cjspark.annuli`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Minimum Deployments**: `iOS 16.0`
4. 保存到任意位置（例如桌面）

### 第 2 步：添加 Supabase 依赖

1. Xcode → **File → Add Package Dependencies…**
2. 搜索框粘贴：`https://github.com/supabase/supabase-swift`
3. 选择版本：`Up to Next Major Version` → `2.0.0`
4. 勾选 **Supabase** → **Add Package**

### 第 3 步：导入源文件

1. 在 Finder 中找到本项目的 `AnnuliSwift/` 文件夹
2. **全选**所有子文件夹（Config, Models, Services, Domain, Extensions, ViewModels, Views）
3. 拖进 Xcode 的 project navigator（左侧文件树）
4. 弹出对话框：勾选 **Copy items if needed** + **Create groups** → Finish
5. 删除 Xcode 默认生成的 `ContentView.swift` 和 `{ProjectName}App.swift`（我们的 `AnnuliApp.swift` 替代它们）

### 第 4 步：添加树图片资源

将原 Next.js 项目 `public/assets/tree/` 下的图片（`tree-1.png` 至 `tree-5.png`、`fruit-a.png` 至 `fruit-d.png`）拖入 Xcode 的 **Assets.xcassets**，保持文件名不变。

### 第 5 步：编译运行

1. 选择模拟器（iPhone 15 Pro 或更高）
2. 按 **⌘R** 编译
3. 首次运行会提示登录 — 使用现有 Supabase 账号

---

## 架构概览

```
AnnuliApp.swift          ← @main 入口，注入全局状态
├── AuthViewModel        ← 监听 Supabase 认证状态
├── PrefsViewModel       ← 全局偏好缓存（EnvironmentObject）
├── TimerViewModel       ← 全局计时器（EnvironmentObject）
│
├── LoginView            ← 未登录时显示
└── MainTabView          ← 已登录时显示
    ├── CalendarRootView  ← 日历 + 时间网格
    ├── TreeRootView      ← 生命树（列表/森林/树形）
    ├── HobbiesRootView   ← 活动管理
    ├── ReviewRootView    ← 复盘分析
    └── TimerBarView      ← 计时器悬浮条
```

## 注意事项

- **Supabase 凭据**：`Config/Supabase.swift` 中的 anon key 是公开密钥（Row Level Security 保护数据安全），可以放在客户端代码里。
- **Swift Charts**：`DailyBarChartView` 使用 `@available(iOS 16, *)` 检查，`TimeCategoryDonutView` 中的 `SectorMark` 需要 iOS 17+，低版本有降级实现。
- **树图片**：`TreeBoardView` 和 `TreeStageCalculator` 引用名为 `tree-1` 至 `tree-5` 的图片资源，需要手动迁移。
- **App Store 上架还需要**：隐私政策页面 URL、App 图标（1024×1024）、截图（6.7"和6.1"各至少一张）。
