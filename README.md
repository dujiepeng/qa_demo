# qa_flutter

`qa_flutter` 是一个用于全量测试环信 IM 功能的 Flutter QA App。

它的核心目标不是做业务展示，而是为 QA、研发联调、SDK 功能回归提供一个可操作、可观察、可复现的测试壳。项目覆盖单聊、群聊、聊天室、会话、联系人、设备、用户属性、日志、版本检查、多环境配置等能力，并同时维护手机端与 Pad 端测试入口。

## 项目定位

- 用于验证 `im_flutter_sdk` 能力是否可用、可回归、可观测
- 用于承载原子化测试入口，而不是面向终端用户的业务流程
- 优先保证测试覆盖、调试可见性、日志可追踪性
- 不以产品化 UI 为第一目标

## 技术栈

- Flutter / Dart
- `im_flutter_sdk`
- `provider`
- `shared_preferences`
- `intl`
- `chat_uikit_theme`

## 关键目录

- `lib/main.dart`
  - 应用入口，注入全局状态，配置路由和共享背景
- `lib/pages/single`
  - 单聊与联系人相关测试页面
- `lib/pages/group`
  - 群组相关测试页面
- `lib/pages/chatroom`
  - 聊天室相关测试页面
- `lib/pages/conversation`
  - 会话相关测试页面
- `lib/mobile`
  - 移动端测试入口与附属页面
- `lib/pad`
  - Pad 端测试入口与布局
- `lib/common/widgets`
  - 通用组件、对话框、日志面板、布局组件
- `lib/common/utils`
  - 控制器、日志工具、版本管理、连接状态等
- `lib/theme`
  - 主题色、应用设置
- `lib/config`
  - 运行时配置和版本配置
- `test`
  - widget test 与定向单测

## 关键能力

- 单聊、群聊、聊天室基础与专项功能测试
- 聊天室消息定向发送、撤回、修改及相关回调日志验证
- 会话列表、联系人状态、黑名单等辅助验证链路
- 多环境配置与服务器切换
- 当前用户资料、其他登录设备、推送昵称等附属能力测试
- SDK 日志查看、应用内日志面板、连接状态提示
- 基于 GitHub Release 的版本检查能力
- 手机 / Pad 双端测试入口

## 聊天室消息修改

- 聊天室消息日志长按菜单提供 `修改` 操作，用固定英文内容 `Chatroom edited message` 修改文本/自定义消息 body，并写入固定 ext `qa_chatroom_edit=chatroom_edit_ext_updated`。
- 文件、视频、音频、图片、位置和合并转发消息的 `修改` 操作只修改 ext，不替换原消息 body。
- 命令消息不展示修改入口；收到 `onMessageContentChanged` 后会记录修改回调日志。

## 运行与验证

常用命令：

```bash
flutter test
flutter analyze
```

如果全局 Flutter/Dart 版本与项目要求不兼容，优先使用项目本地 `fvm` / Flutter 工具链执行验证命令。

APK 版本直接来自 `pubspec.yaml` 的 `version:`，其中 `+` 前是 Android `versionName`，`+` 后是 `versionCode`。执行 `fvm flutter build apk --release` 时会自动带上这个版本；如需临时覆盖，可使用 `--build-name` 和 `--build-number`，但正式发布应保持 `pubspec.yaml`、`changelog.md` 和 Git tag 一致。

针对局部改动，建议优先运行相关测试文件，例如：

```bash
flutter test test/my_page_mobile_test.dart
flutter test test/my_user_profile_page_mobile_test.dart
flutter analyze lib/mobile/my_page_mobile.dart
```

## 开发约定

- 这是 QA 工具，不要把测试入口“产品化”到失去调试价值
- 保留显式按钮、状态提示、日志与环境配置入口
- 修改共享能力时，检查移动端与 Pad 端是否都需要同步
- 涉及 SDK 调用的页面，优先保留或扩展可注入回调，方便 widget test
- 改动后优先补定向测试，而不是只依赖手工验证

## 文档说明

- `case_list.md` 维护官方文档能力与本地 QA 用例覆盖状态；补充或完成用例时应同步更新
- 面向代码代理的执行约定见 `AGENTS.md`
- 发布与版本规则也统一维护在 `AGENTS.md`
