# LogView 治理设计

## 背景

当前 `LogView` 被单聊、群组、聊天室等多个页面复用，已经承担了以下几类职责：

- 日志数据展示
- 长按菜单展示
- 菜单动作回调
- 行内容样式变更
- 页面侧消息对象绑定

现状可以工作，但随着页面增多和菜单动作持续扩展，出现了三个明显问题：

- 页面要重复编写长按菜单项，接入成本偏高
- `LogView` 的菜单定义过于轻量，难以统一菜单样式和扩展条件
- 日志项缺少持久、可感知的操作反馈，用户做完动作后容易忘记刚刚操作了哪一条

本轮治理目标是：在不改变核心使用习惯的前提下，让 `LogView` 更容易复用、更容易扩展长按菜单，并支持日志项级别的持久行内提示。

## 目标

- 页面以更简单的方式声明长按菜单动作
- 页面回调时更容易判断当前触发的动作和目标日志
- 菜单项支持定义视觉样式，例如危险态、强调色、图标
- 日志项支持可选的“行内 overlay 提示”，展示在当前 item 中心区域
- overlay 文案不拼接到原始日志文本，不影响文本复制
- 让单聊、群组、聊天室复用同一套能力，减少重复代码

## 非目标

- 不改动全局 SDK 日志面板 `LogPanel`
- 不把 `LogView` 改造成虚拟化复杂日志系统
- 不在本轮引入跨页面共享的全局日志数据仓库
- 不做一次性插件系统，避免过度设计

## 方案概览

采用“声明式 `LogAction` + 日志项内建 overlay 状态”的方案。

### 核心思路

1. 页面不再直接构造轻量 `LogMenuItem` 列表，而是传入一组 `LogAction`
2. `LogView` 统一负责长按菜单展示、菜单样式渲染和 action 触发
3. action 执行完成后，允许返回一个结构化结果 `LogActionResult`
4. `LogView` / `LogController` 根据结果更新对应日志项的 UI 状态
5. 如果结果中带有 overlay 文案，则在该日志项中央叠加一层持久提示

## 数据模型调整

### `LogEntry`

在现有字段基础上增加 UI 状态字段：

- `overlayLabel`：当前日志项的持久提示文案
- `overlayStyle`：提示样式，支持默认、成功、警告、错误、信息等

约束如下：

- `overlayLabel` 仅用于 UI，不参与日志正文拼接
- 原始日志内容仍使用 `content`
- 复制日志时默认只复制原始文本，不包含 overlay

### `LogAction`

新增统一动作模型，用于替代当前页面直接传 `LogMenuItem`：

- `id`：动作唯一标识，便于页面区分和测试
- `title`：菜单文案
- `icon`：可选图标
- `foregroundColor`：可选前景色
- `isDestructive`：是否危险动作
- `isVisible(LogEntry entry)`：决定是否展示
- `onSelected(LogEntry entry)`：动作执行逻辑

其中 `onSelected` 返回：

- `Future<LogActionResult?>`

如果返回 `null`，表示只执行动作，不修改 item overlay。

### `LogActionResult`

新增动作执行结果类型，支持页面用最轻量方式反馈 UI：

- `overlayLabel`：设置或更新当前 item 的 overlay 文案
- `overlayStyle`：当前 overlay 的样式
- `clearOverlay`：清除当前 overlay
- `content`：可选，替换日志项内容
- `color`：可选，更新日志项颜色
- `style`：可选，更新日志项文本样式

这样页面侧只需要返回结果，不需要再自己访问 controller 修改 item。

## 视图结构调整

### `LogView`

`LogView` 保留“日志标题 + 清空按钮 + 列表”结构，但重构职责：

- 负责渲染统一菜单
- 负责把 action 转为菜单项
- 负责在 action 执行后更新对应日志项状态
- 负责日志项的 overlay 展示

### 日志项渲染

把单个日志 item 拆成独立组件，例如 `LogViewItem`。

渲染结构改为：

- 最底层：原始日志文本
- 中间层：日志项背景 / 文本样式
- 最上层：居中 overlay 文案层

overlay 层使用 `Stack` + `Positioned.fill` + `IgnorePointer`：

- `IgnorePointer` 确保 overlay 不拦截复制或其他文本选择行为
- overlay 居中显示在 cell 中央
- 如果未设置 `overlayLabel`，则不渲染该层

## 菜单扩展体验

### 页面接入方式

页面从“直接构造菜单 UI”改为“声明动作”：

- 单聊页声明自己的消息类 action
- 群组页和聊天室页声明复制类和场景类 action
- 复制、危险操作等共用能力下沉为通用 action 工厂

### 推荐使用方式

保留页面传入动作列表，但把公用动作下沉到 helper：

- `LogActions.copy()`
- `LogActions.deleteRemoteMessage()`
- `LogActions.recallMessage()`

页面可以直接复用，也可以按需组合自定义动作。

这样既保持简单传入，又避免过重的全局注册机制。

## 性能治理

本轮只做低风险优化：

- 把日志 item 抽成独立 widget，降低 `LogView` 主体复杂度
- 避免页面反复手动修改同一条日志时散落多处 controller 操作
- 统一在 controller 中做 item 状态更新，减少页面重复逻辑

暂不引入更重的列表虚拟化和复杂 diff 机制，避免本轮改动范围失控。

## 兼容与迁移

为降低接入成本，建议保留一层兼容：

- 可以先保留 `LogMenuItem`，但 `LogView` 内部转为 `LogAction`
- 页面逐步迁移到新接口

如果实现成本可控，也可以直接替换旧接口，但要同步改完：

- `single_chat_page.dart`
- `group_page.dart`
- `room_page.dart`

## 测试计划

- `LogView` widget test
  - 长按后展示统一菜单
  - action 返回 overlay 文案时，当前 item 显示居中提示
  - action 返回 `null` 时，不显示 overlay
  - overlay 不影响原始日志文本复制

- `LogController` unit test
  - 能更新指定日志项的 overlay 文案
  - 能清除 overlay
  - 能同时更新内容、颜色、样式和 overlay

- 页面级回归
  - 单聊页的复制/撤回/修改等动作仍正常工作
  - 群组页和聊天室页的复制动作迁移后正常工作

## 风险与控制

### 风险

- 旧页面迁移过程中，菜单行为可能出现缺项
- overlay 层如果处理不好，可能影响文字点击或复制体验
- action 与 controller 的职责边界不清，可能再次耦合

### 控制

- overlay 使用 `IgnorePointer`
- 通过结构化 `LogActionResult` 限制页面侧直接操作 view 状态
- 优先完成单测，再迁移三个复用页面

## 推荐实施顺序

1. 为 `LogEntry` / `LogController` 增加 overlay 状态支持
2. 新增 `LogAction` / `LogActionResult`
3. 重构 `LogView` 为统一菜单和 item overlay 展示
4. 迁移单聊、群组、聊天室页面
5. 补齐 widget test 和 controller test
