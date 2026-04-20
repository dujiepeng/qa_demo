# Mobile Log Overlay Filter Design

## Goal

为首页悬浮日志窗增加关键字过滤能力，帮助 QA 在不离开首页的情况下快速缩小日志范围，且不影响底层 SDK 日志采集和详情页日志能力。

## Scope

- 仅修改首页悬浮日志窗中的日志面板。
- 支持按关键字包含匹配过滤当前展示的日志文本。
- 过滤开启后，新增日志继续参与匹配，命中的内容实时显示。
- “复制全部”调整为复制当前过滤后的可见内容。

## Out Of Scope

- 不修改详情页日志查看页。
- 不修改 SDK 日志文件写入、同步策略或日志内容格式。
- 不引入按级别、tag、时间段等复杂结构化筛选。

## Current Context

- `lib/common/widgets/layout/mobile_log_overlay.dart` 负责首页浮窗容器。
- `lib/common/widgets/log_panel/log_panel.dart` 负责日志面板 UI，目前直接展示 `LogPanelController.content`。
- `lib/common/widgets/log_panel/log_panel_controller.dart` 负责日志文件同步和清空，不承担展示层状态。

## Proposed Approach

### UI

在 `LogPanel` 顶部工具栏下方增加一个轻量过滤输入区域，默认收起，通过筛选按钮展开。输入关键字后立即刷新展示文本，并提供清空输入的操作。

### Data Flow

- `LogPanelController` 继续只维护原始日志文本。
- `LogPanel` 新增本地过滤状态，例如过滤关键字和过滤后的可见文本。
- 每次原始日志内容变化时，`LogPanel` 基于当前关键字重新计算显示文本，因此新增日志会自动参与过滤。

### Matching Rule

- 以“按行过滤”为准。
- 空关键字时显示全部原始日志。
- 非空关键字时，仅保留包含关键字的日志行。
- 先采用区分大小写不敏感匹配，降低 QA 输入成本。

### Copy Behavior

- “复制全部”复制当前浮窗里实际可见的文本。
- 无过滤时复制全部原始内容。
- 有过滤时复制过滤后的内容。

## Error Handling

- 过滤关键字为空时不报错，直接回退到完整日志。
- 没有匹配结果时，面板显示空结果文案，而不是误导成“日志未加载”。
- 清空日志后，展示内容应同步清空，并保留当前过滤关键字，便于继续观察后续命中新日志。

## Testing

- 为 `LogPanel` 增加 widget 测试，覆盖：
  - 输入关键字后只显示匹配行
  - 新日志到达后命中关键字的行会实时出现
  - 复制操作复制的是过滤后的可见内容
  - 无匹配结果时显示明确提示
