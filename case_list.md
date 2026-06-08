# 环信 IM Android 入门指引能力对照清单

## 审计说明

- 审计日期：2026-06-03。
- 官方基准：[Android 入门指引](https://doc.easemob.com/document/android/beginner_guide.html) 及其 Android SDK 侧边栏功能页；官网概述页显示最近更新于 2026-06-03。
- 本地项目：Flutter QA app。虽然官方基准页是 Android 文档，本地通过 `im_flutter_sdk` 调用 Android 原生 SDK 能力。
- 本清单用于核对 QA app 是否提供可操作入口、真实 SDK 调用和必要回调。它不代表服务端套餐、REST 权限或控制台配置已经开通。
- 状态定义：
  - `已实现`：存在 QA 入口或回调监听，并调用真实 SDK / 服务端返回数据。
  - `部分实现`：仅覆盖部分场景，或存在本地 UI 但未调用对应 SDK。
  - `未实现`：本地未找到可操作入口或真实 SDK 调用。
  - `控制台/服务端`：不属于客户端 app 功能，需要在控制台或业务服务端完成。

## 1. 接入与登录

| Case | 官方能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| LOGIN-001 | 注册环信开发者账号 | 控制台/服务端 | [官方控制台说明](https://doc.easemob.com/product/console/account_register.html) | 不应在 QA app 内实现。 |
| LOGIN-002 | 创建应用并获取 App Key | 控制台/服务端 | `lib/theme/app_settings.dart`、`lib/common/server_config_page.dart` | QA app 可配置已有 App Key，但不能在客户端创建应用。 |
| LOGIN-003 | 开通 IM 套餐和增值服务 | 控制台/服务端 | [官方套餐说明](https://doc.easemob.com/product/pricing_method.html) | 不应在 QA app 内实现。 |
| LOGIN-004 | 创建 IM 用户 | 控制台/服务端 | 未找到客户端注册入口 | 官方建议通过 REST API 或控制台创建用户。 |
| LOGIN-005 | 业务服务端获取 App Token / User Token | 控制台/服务端 | 未找到业务服务端 Token 接口 | QA app 当前不承担服务端 Token 签发。 |
| LOGIN-006 | 导入 SDK | 已实现 | `pubspec.yaml` 中使用 `im_flutter_sdk` | Flutter 插件负责 Android SDK 集成。 |
| LOGIN-007 | 初始化 SDK | 已实现 | `lib/common/mixins/login_logic_mixin.dart`：`EMClient.getInstance.init(options)` | 支持公有云和自定义服务器配置。 |
| LOGIN-008 | 密码主动登录 | 已实现 | `lib/common/mixins/login_logic_mixin.dart`：`loginWithPassword` | Mobile 和 Pad 登录页复用该逻辑。 |
| LOGIN-009 | Token 主动登录 | 未实现 | 未找到 `loginWithToken` 调用 | 当前登录表单仅支持 UID + Password。 |
| LOGIN-010 | 自动登录 | 未实现 | `EMOptions` 固定设置 `autoLogin: false` | 冷启动会初始化 SDK，但不是 SDK 自动登录。 |
| LOGIN-011 | 主动退出登录 | 已实现 | `lib/common/session_scope.dart`、`lib/common/widgets/me_page_content.dart` | 调用真实 `logout()`。 |
| LOGIN-012 | 连接状态监听 | 已实现 | `lib/pages/home_page.dart`：`EMConnectionEventHandler` | 覆盖连接、断开、鉴权失败、Token 过期、被踢等事件。 |
| LOGIN-013 | 获取 SDK 日志 | 已实现 | `lib/common/utils/log_file_helper.dart`、各聊天页“日志”入口 | 调用真实 `compressLogs` 并展示日志。 |
| LOGIN-014 | 私有云服务器配置 | 已实现 | `lib/common/server_config_page.dart`、`ensureSdkInit` | 支持 REST、TCP/WebSocket、端口、TLS 开关和环境切换；内置 TKE、qa隔舱、开发沙箱、ebs。 |

## 2. 用户、联系人与 Presence

官方入口：[用户关系](https://doc.easemob.com/document/android/user_relationship.html)、[用户属性](https://doc.easemob.com/document/android/userprofile.html)、[Presence](https://doc.easemob.com/document/android/presence.html)、[多设备登录](https://doc.easemob.com/document/android/multi_device.html)、[用户信息自动管理](https://doc.easemob.com/document/android/userinfo_provider.html)。

| Case | 能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| USER-001 | 获取联系人列表 | 已实现 | `lib/pages/single/contact_api.dart`：`fetchAllContacts` | 联系人列表页和 Presence 页均使用真实数据。 |
| USER-002 | 添加联系人 | 已实现 | `lib/pages/single/single_chat_list_page.dart`：`addContact` | 支持发送好友申请。 |
| USER-003 | 接收好友申请通知 | 已实现 | `lib/pages/home_page.dart`：`onContactInvited` | 首页展示真实 SDK 回调。 |
| USER-004 | 接受 / 拒绝好友申请 | 已实现 | `lib/pages/single/single_chat_list_page.dart`：`acceptInvitation`、`declineInvitation` | 联系人列表展示申请卡片。 |
| USER-005 | 删除联系人 | 已实现 | `lib/pages/single/single_chat_list_page.dart`：`deleteContact` | 使用真实 SDK 调用。 |
| USER-006 | 设置联系人备注 | 已实现 | `lib/pages/single/contact_presence_page.dart`：`setContactRemark` | 成功后重新拉取联系人。 |
| USER-007 | 加入联系人黑名单 | 已实现 | `lib/pages/single/contact_api.dart`：`addUserToBlockList` | 联系人列表与 Presence 页均有入口。 |
| USER-008 | 获取联系人黑名单 | 已实现 | `lib/pages/single/black_list_page.dart`：`fetchBlockIds` | 有独立黑名单页。 |
| USER-009 | 移出联系人黑名单 | 已实现 | `lib/pages/single/black_list_page.dart`：`removeUserFromBlockList` | 使用真实 SDK 调用。 |
| USER-010 | 获取自己的用户属性 | 已实现 | `lib/mobile/my_user_profile_page_mobile.dart`：`fetchOwnInfo` | 当前入口在 Mobile“我的”。 |
| USER-011 | 修改自己的用户属性 | 部分实现 | `lib/mobile/my_user_profile_page_mobile.dart`：`updateUserInfo` | 已支持昵称、生日、邮箱；未覆盖头像、电话、性别、签名等全部字段。 |
| USER-012 | 查询其他用户属性 | 已实现 | `lib/mobile/user_info_lookup_page_mobile.dart`：`fetchUserInfoById` | Mobile“我的”支持输入 1-100 个用户 ID 批量查询全部用户属性。 |
| USER-013 | 发布 Presence 自定义状态 | 已实现 | `lib/pages/single/contact_presence_page.dart`：`publishPresence` | 联系人与 Presence 页 AppBar 支持发布自定义状态。 |
| USER-014 | 查询 Presence 状态 | 已实现 | `lib/pages/single/contact_api.dart`：`fetchPresenceStatus` | 页面展示实际在线 / 离线状态。 |
| USER-015 | 订阅 Presence | 已实现 | `lib/pages/single/contact_api.dart`：`subscribe` | 联系人长按菜单可操作。 |
| USER-016 | 取消订阅 Presence | 已实现 | `lib/pages/single/contact_api.dart`：`unsubscribe` | 联系人长按菜单可操作。 |
| USER-017 | 获取已订阅 Presence 用户 | 已实现 | `lib/pages/single/contact_api.dart`：`fetchSubscribedMembers` | 进入 Presence 页时拉取真实订阅列表。 |
| USER-018 | Presence 变更回调 | 已实现 | `lib/pages/single/contact_presence_page.dart`：Presence event handler | 回调更新联系人状态展示。 |
| USER-019 | 获取其他登录设备 | 已实现 | `lib/pages/single/contact_api.dart`：`fetchLoggedInDevices` | Mobile“我的”中有设备页。 |
| USER-020 | 踢其他设备下线 | 已实现 | `lib/pages/single/contact_api.dart`：`kickDevice` | 需要真实账号密码和 resource。 |
| USER-021 | 多设备登录事件监听 | 已实现 | `lib/pages/home_page.dart`：`onUserDidLoginFromOtherDevice` 等 | 首页展示真实回调。 |
| USER-022 | 用户信息自动管理 | 未实现 | 未找到 `userinfo_provider` 对应自动资料提供 / 缓存管理入口 | 官网用户相关侧边栏独立功能页；当前 QA app 只提供手动查询 / 修改自己的用户属性。 |

## 3. 消息管理

官方入口：[消息概述](https://doc.easemob.com/document/android/message_overview.html)、[发送消息](https://doc.easemob.com/document/android/message_send.html)、[接收消息](https://doc.easemob.com/document/android/message_receive.html)、[获取历史消息](https://doc.easemob.com/document/android/message_retrieve.html)、[消息撤回](https://doc.easemob.com/document/android/message_recall.html)、[消息修改](https://doc.easemob.com/document/android/message_modify.html)。

| Case | 能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| MSG-001 | 发送文本消息 | 已实现 | `single_chat_page.dart`、`group_page.dart`、`room_page.dart` | 单聊、群聊、聊天室均有输入框。 |
| MSG-002 | 发送图片消息 | 已实现 | 三类聊天页“图片”按钮 | 使用本地测试资源并调用真实 SDK。 |
| MSG-003 | 发送视频消息 | 已实现 | 三类聊天页“视频”按钮 | 使用本地测试资源并调用真实 SDK。 |
| MSG-004 | 发送语音消息 | 已实现 | 三类聊天页“语音”按钮 | 使用本地测试资源并调用真实 SDK。 |
| MSG-005 | 发送文件消息 | 已实现 | 三类聊天页“文件”按钮 | 使用本地测试资源并调用真实 SDK。 |
| MSG-006 | 发送位置消息 | 已实现 | 三类聊天页“位置”按钮 | 使用固定 QA 经纬度。 |
| MSG-007 | 发送自定义消息 | 已实现 | 三类聊天页“自定义”按钮 | 使用固定 QA event 和 params。 |
| MSG-008 | 发送命令消息 | 已实现 | 单聊、群聊、聊天室消息类型区“命令”按钮：`createCmdSendMessage` | 固定发送 QA action `action1`，分别设置 `Chat`、`GroupChat`、`ChatRoom`。 |
| MSG-009 | 接收消息回调 | 已实现 | 三类聊天页：`onMessagesReceived` | 将 SDK 消息对象写入日志。 |
| MSG-010 | 消息扩展字段 ext | 已实现 | 三类聊天页：`msg.attributes = {...}` | QA 场景固定写入 ext。 |
| MSG-011 | 只投递在线用户 | 部分实现 | 单聊、群聊页：`deliverOnlineOnly` | 聊天室页未提供该开关。 |
| MSG-012 | 群组定向消息 | 已实现 | `lib/pages/group/group_page.dart`：群聊发送前设置 `receiverList` | 输入框支持逗号 / 换行拆分，限制最多 20 个接收方。 |
| MSG-013 | 聊天室定向消息 | 已实现 | `room_page.dart`：`receiverList`、成员选择器、全选 | 最多 20 个接收方，使用真实成员列表。 |
| MSG-014 | 单聊消息已读 ACK | 已实现 | `single_chat_page.dart`：`sendMessageReadAck` | 收到的单聊消息长按可操作。 |
| MSG-015 | 群消息已读回执 | 已实现 | `lib/pages/group/group_page.dart`：`needGroupAck`、`sendGroupMessageReadAck`、`fetchGroupAcks` | 群消息日志长按可发送群回执和查询回执详情，并监听群回执事件。 |
| MSG-016 | 消息送达 / 已读回调 | 已实现 | `single_chat_page.dart`：`onMessagesDelivered`、`onMessagesRead` | 单聊日志展示状态。 |
| MSG-017 | 拉取服务端历史消息 | 部分实现 | `single_chat_page.dart`：“拉消息1 / 拉消息2” | 当前只有单聊入口；群聊、聊天室未提供拉取入口。 |
| MSG-018 | 单向删除服务端消息 | 部分实现 | 单聊和聊天室消息长按菜单 | 单聊、聊天室已实现；群聊未实现。 |
| MSG-019 | 按时间单向删除服务端消息 | 部分实现 | 聊天室消息长按“按时间删” | 当前只在聊天室提供入口。 |
| MSG-020 | 撤回消息 | 部分实现 | 单聊和聊天室消息长按“撤回” | 单聊、聊天室已实现并监听回调；群聊未实现。 |
| MSG-021 | 修改消息 | 部分实现 | 单聊和聊天室消息长按“修改” | 单聊、聊天室已实现；群聊未实现。聊天室遵循 body / ext 限制。 |
| MSG-022 | 消息置顶 / 取消置顶 | 已实现 | `single_chat_page.dart`：`pinMessage`、`unpinMessage` | 当前入口位于单聊消息日志。 |
| MSG-023 | 获取置顶消息列表 | 已实现 | `single_chat_page.dart`：“置顶列表” | 使用真实 `fetchPinnedMessages`。 |
| MSG-024 | Reaction 添加 / 删除 / 回调 | 已实现 | `single_chat_page.dart`、`single_chat_reaction.dart` | 当前入口位于单聊消息日志。 |
| MSG-025 | 消息转发 | 未实现 | 未找到转发入口 | 未覆盖逐条转发和合并转发。 |
| MSG-026 | 回复 / 引用消息 | 未实现 | 未找到引用消息入口 | 未覆盖 quote 场景。 |
| MSG-027 | 插入本地消息 / 导入消息 | 未实现 | 未找到 insert / import 调用 | 无 QA 入口。 |
| MSG-028 | 搜索消息 | 未实现 | 未找到消息搜索调用 | 无 QA 入口。 |
| MSG-029 | 消息翻译 | 未实现 | 未找到翻译调用 | 属于需开通的增值能力。 |
| MSG-030 | 输入状态指示 | 未实现 | 未找到 typing indication 调用 | 无 QA 入口。 |
| MSG-031 | 子区 / Thread | 未实现 | 未找到 Thread 管理入口 | 无 QA 入口。 |
| MSG-032 | 流式消息 | 未实现 | 未找到 stream message 调用 | 无 QA 入口。 |
| MSG-033 | 内容审核配置 | 控制台/服务端 | 未找到客户端开关 | 属于服务端增值能力。 |
| MSG-034 | 获取本地历史消息 | 未实现 | 未找到 `loadMessages` / 本地历史分页加载 QA 入口 | 官网消息概述表独立列出“获取本地历史消息”。 |
| MSG-035 | 更新本地消息 | 未实现 | 未找到 `updateMessage` 本地消息更新入口 | 区分于 `MSG-021` 的服务端消息修改。 |
| MSG-036 | 删除本地历史消息 | 未实现 | 未找到本地消息删除 / 清理指定会话本地消息入口 | 区分于 `MSG-018`、`MSG-019` 的服务端历史消息删除。 |
| MSG-037 | 消息多端同步 | 部分实现 | `home_page.dart`、聊天页 SDK event handlers | 已监听部分消息 / 会话相关回调，但未提供覆盖全部消息多端事件的专门 QA 面板。 |
| MSG-038 | 获取消息流量统计 | 未实现 | 未找到消息流量统计 SDK / REST 入口 | 官网 Android 消息概述表独立列出，Flutter 列不支持；本 QA app 未提供 Android 原生专项入口。 |

## 4. 会话管理

官方入口：[会话管理概览](https://doc.easemob.com/document/android/conversation_overview.html)。

| Case | 能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| CONV-001 | 获取服务端会话列表 | 已实现 | `lib/pages/conversation/conversation_list_page.dart`：`fetchConversationsByOptions` | 支持分页。 |
| CONV-002 | 加载本地会话列表 | 已实现 | `conversation_list_page.dart`：`loadAllConversations` | 用于补充本地聊天室会话。 |
| CONV-003 | 展示单聊、群聊、聊天室会话 | 已实现 | `conversation_list_page.dart` | 三种 `EMConversationType` 均有展示。 |
| CONV-004 | 获取会话未读数 | 已实现 | `conversation_list_page.dart`：`conversation.unreadCount()` | 会话列表展示真实未读数。 |
| CONV-005 | 会话设置为已读 | 已实现 | `conversation_list_page.dart`：`markAllMessagesAsRead` | 长按会话可操作。 |
| CONV-006 | 获取会话最后一条消息 | 已实现 | `conversation_list_page.dart`：`latestMessage()` | 会话列表展示摘要。 |
| CONV-007 | 会话置顶 / 取消置顶 | 已实现 | `conversation_list_page.dart`：`pinConversation` | 长按会话可操作。 |
| CONV-008 | 会话标记 Mark | 已实现 | `conversation_list_page.dart`：`addRemoteAndLocalConversationsMark`、`deleteRemoteAndLocalConversationsMark` | 支持 Mark1、Mark2、Mark3 和筛选。 |
| CONV-009 | 删除服务端会话及消息 | 已实现 | `conversation_list_page.dart`：`deleteRemoteConversation` | 长按会话可操作。 |
| CONV-010 | 会话变更监听并刷新列表 | 已实现 | `conversation_list_page.dart`：`EMChatEventHandler` | 覆盖收到、已读、送达、撤回、会话更新。 |
| CONV-011 | 清空本地会话消息但保留会话 | 未实现 | 未找到独立入口 | 当前删除入口调用服务端删除会话。 |
| CONV-012 | 会话级已读回执发送 | 未实现 | 未找到 `sendConversationReadAck` 调用 | 当前仅支持本地会话设置为已读。 |
| CONV-013 | 获取 / 创建指定会话 | 部分实现 | `single_chat_page.dart`、`group_page.dart`、`room_page.dart` 通过发送消息自然创建会话 | 未提供 `getConversation(createIfNotExists)` 的独立 QA 入口。 |
| CONV-014 | 拉取空会话 | 已实现 | `conversation_list_page.dart`：`EMFetchConversationOptions` 中 `includeEmptyConversation: true` | 服务端会话列表会包含空会话。 |
| CONV-015 | 设置指定消息为已读 | 未实现 | 未找到 `markMessageAsRead` 单条消息入口 | 当前仅支持整个会话设置为已读。 |
| CONV-016 | 获取会话全部消息数 | 未实现 | 未找到 `getAllMsgCount` / 本地总消息数展示入口 | 无 QA 入口。 |
| CONV-017 | 获取对方发来的最后一条消息 | 未实现 | 未找到 `latestMessageFromOthers` 入口 | 当前只展示会话最后一条消息。 |
| CONV-018 | 会话扩展字段 set/get | 未实现 | 未找到 `setExtField` / `getExtField` 入口 | 无 QA 入口。 |

## 5. 群组管理

官方入口：[群组管理概览](https://doc.easemob.com/document/android/group_overview.html)、[创建和管理群组](https://doc.easemob.com/document/android/group_manage.html)、[群成员管理](https://doc.easemob.com/document/android/group_members.html)。

| Case | 能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| GROUP-001 | 获取已加入群组列表 | 已实现 | `lib/pages/group/group_list_page.dart`：`fetchJoinedGroupsFromServer` | 支持分页。 |
| GROUP-002 | 获取公开群列表 / 搜索公开群 | 未实现 | 未找到公开群列表或搜索入口 | 当前可手动输入群组 ID。 |
| GROUP-003 | 创建群组 | 已实现 | `lib/pages/group/group_page.dart`：“创建” | 支持群类型、最大人数、邀请确认、邀请成员、原因。 |
| GROUP-004 | 获取群组详情 | 已实现 | `group_page.dart`：`fetchGroupInfoFromServer` | 使用真实服务端详情。 |
| GROUP-005 | 加入公开群 | 已实现 | `group_page.dart`：`joinPublicGroup` | 根据真实群详情判断审批逻辑。 |
| GROUP-006 | 申请加入需审批群 | 已实现 | `group_page.dart`：`requestToJoinPublicGroup` | 发送真实申请。 |
| GROUP-007 | 审批入群申请 | 已实现 | `group_list_page.dart`：`acceptJoinApplication`、`declineJoinApplication` | 群主 / 管理员收到真实入群申请回调后，可在群组列表同意或拒绝。 |
| GROUP-008 | 接收群邀请 | 已实现 | `lib/pages/home_page.dart`、`group_invitation_store.dart` | 保存真实 SDK 邀请回调并展示。 |
| GROUP-009 | 接受 / 拒绝群邀请 | 已实现 | `group_list_page.dart`：`acceptInvitation`、`declineInvitation` | 群列表展示邀请卡片。 |
| GROUP-010 | 监听邀请接受 / 拒绝 | 已实现 | `home_page.dart`、`group_page.dart` | 邀请方可观察真实回调。 |
| GROUP-011 | 退出群组 | 已实现 | `group_page.dart`：`leaveGroup` | 使用真实 SDK 调用。 |
| GROUP-012 | 解散群组 | 已实现 | `group_page.dart`：`destroyGroup` | 仅群主按钮可用，含二次确认。 |
| GROUP-013 | 获取群成员列表 | 已实现 | `lib/pages/group/group_members_page.dart`：`fetchMemberListFromServer` | 支持分页。 |
| GROUP-014 | 邀请 / 添加群成员 | 已实现 | `group_members_page.dart`：`addMembers` | 使用真实 SDK 调用。 |
| GROUP-015 | 移出群成员 | 已实现 | `lib/pages/group/group_members_page.dart`：`removeMembers` | 群成员操作菜单可将指定成员移出群组。 |
| GROUP-016 | 群黑名单管理 | 已实现 | `group_members_page.dart`：`blockMembers`、`fetchBlockListFromServer`、`unblockMembers` | 群成员操作菜单支持加入黑名单，顶部黑名单入口支持获取与移出。 |
| GROUP-017 | 添加群管理员 | 已实现 | `group_members_page.dart`：`addAdmin` | 成员操作菜单。 |
| GROUP-018 | 移除群管理员 | 已实现 | `lib/pages/group/group_admins_page.dart`：`removeAdmin` | 操作后重新拉取服务端管理员列表验证。 |
| GROUP-019 | 转移群主 | 已实现 | `lib/pages/group/group_change_owner_page.dart`：`changeOwner` | 当前页面筛除了管理员候选人。 |
| GROUP-020 | 修改群名称 / 描述 | 已实现 | `group_page.dart`：`updateGroupName`、`updateGroupDesc` | 使用真实 SDK 调用。 |
| GROUP-021 | 获取 / 修改群公告 | 部分实现 | `group_page.dart`：`updateGroupAnnouncement`、`fetchGroupInfoFromServer` | 已支持更新公告并监听变更；未提供独立获取群公告入口。 |
| GROUP-022 | 获取 / 设置群成员名片 | 未实现 | 未找到 namecard 调用 | 无 QA 入口。 |
| GROUP-023 | 禁言群成员 | 已实现 | `group_members_page.dart`：`muteMembers` | 成员操作菜单。 |
| GROUP-024 | 获取群禁言列表 | 已实现 | `lib/pages/group/group_mute_list_page.dart`：`fetchMuteListFromServer` | 支持分页。 |
| GROUP-025 | 解除群成员禁言 | 已实现 | `group_mute_list_page.dart`：`unMuteMembers` | 禁言列表中操作。 |
| GROUP-026 | 全员禁言 / 解除全员禁言 | 已实现 | `group_page.dart`：`muteAllMembers`、`unMuteAllMembers` | 使用真实群详情初始化开关。 |
| GROUP-027 | 获取群白名单 | 已实现 | `lib/pages/group/group_white_list_page.dart`：`fetchAllowListFromServer` | 独立白名单页。 |
| GROUP-028 | 加入 / 移出群白名单 | 已实现 | `group_members_page.dart`、`group_white_list_page.dart` | 使用真实 SDK 调用。 |
| GROUP-029 | 屏蔽 / 解除屏蔽群消息 | 已实现 | `group_page.dart`：`blockGroup`、`unblockGroup` | 普通成员可操作，状态来自服务端群详情。 |
| GROUP-030 | 设置群成员自定义属性 | 已实现 | `group_page.dart`：`setMemberAttributes` | 固定 QA 属性，并监听回调。 |
| GROUP-031 | 群组自定义属性管理 | 未实现 | 未找到 group attributes 增删改查入口 | 当前实现的是群成员属性，不是群组属性。 |
| GROUP-032 | 群共享文件 | 未实现 | 未找到共享文件上传、下载、删除入口 | 无 QA 入口。 |
| GROUP-033 | 群组事件监听 | 部分实现 | `group_page.dart`、`home_page.dart`：`EMGroupEventHandler` | 已监听常用事件，但未覆盖官方文档中的全部群事件。 |
| GROUP-034 | 封禁 / 解禁群组 | 控制台/服务端 | 未找到客户端 SDK 入口 | 官网群组概述说明通过 REST API 封禁 / 解禁指定群组。 |
| GROUP-035 | 获取 app 中的群组列表 | 控制台/服务端 | 未找到客户端 SDK 入口 | 官网群组概述说明通过 REST API 分页获取应用下群组。 |
| GROUP-036 | 查询当前用户已加入群组数量 | 已实现 | `lib/pages/group/group_list_page.dart`：`fetchJoinedGroupCount` | 群组列表页顶部统计入口展示服务端返回数量。 |
| GROUP-037 | 获取单个用户加入的所有群组 | 控制台/服务端 | 未找到客户端 SDK 入口 | 官网群组概述说明通过 REST API 按用户 ID 查询。 |
| GROUP-038 | 查看指定用户是否已加入群组 | 控制台/服务端 | 未找到客户端 SDK 入口 | 官网群组概述说明通过 REST API 查询。 |
| GROUP-039 | 获取单个群成员自定义属性 | 已实现 | `lib/pages/group/group_members_page.dart`：`fetchMemberAttributes` | 群成员操作菜单可查询指定成员全部自定义属性。 |
| GROUP-040 | 群组事件服务端回调 | 控制台/服务端 | 未找到业务服务端回调接收 / 配置入口 | 属于应用服务器 HTTP/HTTPS 回调能力。 |

## 6. 聊天室管理

官方入口：[聊天室管理概览](https://doc.easemob.com/document/android/room_overview.html)、[创建和管理聊天室](https://doc.easemob.com/document/android/room_manage.html)、[聊天室成员管理](https://doc.easemob.com/document/android/room_members.html)、[聊天室属性](https://doc.easemob.com/document/android/room_attributes.html)。

| Case | 能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| ROOM-001 | 获取公开聊天室列表 | 已实现 | `lib/pages/chatroom/room_list_page.dart`：`fetchPublicChatRoomsFromServer` | 支持分页和刷新。 |
| ROOM-002 | 创建聊天室 | 已实现 | `lib/pages/chatroom/room_page.dart`：“创建” | 调用真实 `createChatRoom`；账号需具备服务端权限。 |
| ROOM-003 | 获取聊天室详情 | 已实现 | `room_page.dart`：`fetchChatRoomInfoFromServer` | 使用真实服务端详情。 |
| ROOM-004 | 加入 / 退出聊天室 | 已实现 | `room_page.dart`：`joinChatRoom`、`leaveChatRoom` | 使用真实 SDK 调用。 |
| ROOM-005 | 解散聊天室 | 已实现 | `room_page.dart`：`destroyChatRoom` | 仅所有者按钮可用，含二次确认。 |
| ROOM-006 | 修改聊天室名称 / 描述 | 已实现 | `room_page.dart`：`changeChatRoomName`、`changeChatRoomDescription` | 使用真实 SDK 调用。 |
| ROOM-007 | 获取 / 修改聊天室公告 | 部分实现 | `room_page.dart`：`updateChatRoomAnnouncement`、`fetchChatRoomInfoFromServer` | 已支持更新公告并监听变更；未提供独立获取公告入口。 |
| ROOM-008 | 获取聊天室成员列表 | 已实现 | `lib/pages/chatroom/room_members_page.dart`：`fetchChatRoomMembers` | 支持分页。 |
| ROOM-009 | 移出聊天室成员 | 已实现 | `room_members_page.dart`：`removeChatRoomMembers` | 不展示移除自己的入口。 |
| ROOM-010 | 添加聊天室管理员 | 已实现 | `room_members_page.dart`：`addChatRoomAdmin` | 成员操作菜单。 |
| ROOM-011 | 移除聊天室管理员 | 已实现 | `lib/pages/chatroom/room_admins_page.dart`：`removeChatRoomAdmin` | 管理员列表中操作。 |
| ROOM-012 | 转移聊天室所有者 | 已实现 | `lib/pages/chatroom/room_change_owner_page.dart`：`changeOwner` | 页面校验当前用户是否所有者。 |
| ROOM-013 | 禁言聊天室成员 | 已实现 | `room_members_page.dart`：`muteChatRoomMembers` | 成员操作菜单。 |
| ROOM-014 | 获取聊天室禁言列表 | 已实现 | `lib/pages/chatroom/room_mute_list_page.dart`：`fetchChatRoomMuteList` | 支持分页。 |
| ROOM-015 | 解除聊天室成员禁言 | 已实现 | `room_mute_list_page.dart`：`unMuteChatRoomMembers` | 禁言列表中操作。 |
| ROOM-016 | 全员禁言 / 解除全员禁言 | 已实现 | `room_page.dart`：`muteAllChatRoomMembers`、`unMuteAllChatRoomMembers` | 使用真实聊天室详情初始化开关。 |
| ROOM-017 | 获取聊天室白名单 | 已实现 | `lib/pages/chatroom/room_white_list_page.dart`：`fetchChatRoomAllowListFromServer` | 独立白名单页。 |
| ROOM-018 | 加入 / 移出聊天室白名单 | 已实现 | `room_members_page.dart`、`room_white_list_page.dart` | 使用真实 SDK 调用。 |
| ROOM-019 | 获取聊天室黑名单 | 已实现 | `lib/pages/chatroom/room_block_list_page.dart`：`fetchChatRoomBlockList` | 支持分页。 |
| ROOM-020 | 加入 / 移出聊天室黑名单 | 已实现 | `room_members_page.dart`、`room_block_list_page.dart` | 使用真实 SDK 调用。 |
| ROOM-021 | 设置聊天室自定义属性 | 已实现 | `room_page.dart`：`addAttributes` | 固定写入 QA 属性。 |
| ROOM-022 | 获取聊天室自定义属性 | 已实现 | `room_page.dart`：“取属性”按钮，`fetchChatRoomAttributes` | 固定查询 QA 属性键 `attKey` 并写入日志。 |
| ROOM-023 | 删除聊天室自定义属性 | 已实现 | `room_page.dart`：`removeAttributes` | 固定删除 QA 属性键 `attKey`；无该属性时提示“不存在，无需删除”，并记录真实 SDK 返回。 |
| ROOM-024 | 聊天室事件监听 | 部分实现 | `room_page.dart`：`EMChatRoomEventHandler` | 已监听常用事件，但未覆盖官方文档中的全部聊天室事件。 |
| ROOM-025 | 实时更新聊天室成员人数 | 未实现 | 未找到实时聊天室人数监听 / 展示入口 | 官网聊天室概述独立列出该能力。 |
| ROOM-026 | 强制设置 / 强制删除聊天室属性 | 部分实现 | `room_page.dart`：`removeAttributes(..., force: true)` | 已强制删除固定属性；设置属性未使用 force 参数，且缺少可配置化入口。 |
| ROOM-027 | 聊天室事件服务端回调 | 控制台/服务端 | 未找到业务服务端回调接收 / 配置入口 | 属于应用服务器 HTTP/HTTPS 回调能力。 |

## 7. 离线推送

官方入口：[离线推送概览](https://doc.easemob.com/document/android/push/push_overview.html)。

| Case | 能力 | 状态 | 本地入口 / 证据 | 备注 |
| --- | --- | --- | --- | --- |
| PUSH-001 | 厂商推送集成 | 未实现 | 未找到 FCM、华为、小米、OPPO、vivo、魅族、荣耀推送配置 | 需要 Android 原生配置和厂商控制台信息。 |
| PUSH-002 | 上传 / 更新推送 token | 已实现 | `lib/mobile/push_settings_page_mobile.dart`：`pushManager.bindDeviceToken` | “我的 > 推送设置”输入 notifier name 和真实 token 后绑定。 |
| PUSH-003 | 设置推送昵称 | 已实现 | `lib/mobile/my_page_mobile.dart`：`pushManager.updatePushNickname` | “我的”页设置推送昵称后调用真实 SDK。 |
| PUSH-004 | 推送免打扰 / 静默模式 | 已实现 | `push_settings_page_mobile.dart`：`setSilentModeForAll`、`setConversationSilentMode`、查询 / 清除 / 同步会话静默 | 使用真实 SDK silent mode API。 |
| PUSH-005 | 推送展示字段、扩展、模板 | 部分实现 | `push_settings_page_mobile.dart`：`updatePushDisplayStyle`、`fetchPushConfigsFromServer`、`setPushTemplate`、`getPushTemplate` | 已覆盖展示样式和模板；推送扩展仍需服务端模板 / 原生通知链路验证。 |
| PUSH-006 | 推送消息分类 | 未实现 | 当前 Flutter SDK 未找到消息分类专用 API / 原生通道入口 | 需要厂商通知类别或服务端模板能力配合，不能在客户端伪造。 |
| PUSH-007 | 推送解析 | 未实现 | 未找到原生推送点击解析逻辑 | 需要 Android/iOS 原生通知点击数据链路。 |
| PUSH-008 | 离线消息计数展示 | 已实现 | `lib/common/utils/offline_message_counter.dart`、`home_page.dart` | 这是 SDK 收到离线消息后的 QA 计数，不等同于厂商离线推送集成。 |
| PUSH-009 | 设置推送翻译 | 未实现 | 未找到推送翻译 SDK / 服务端配置入口 | 官网离线推送侧边栏独立功能页。 |
| PUSH-010 | 统一获取消息方案 | 未实现 | 未找到统一解析 / 拉取推送消息方案入口 | `syncConversationsSilentMode` 只同步会话静默设置，不等同于统一获取消息方案。 |

## 8. 建议优先补齐项

| 优先级 | 缺口 | 原因 |
| --- | --- | --- |
| P1 | `MSG-020`、`MSG-021` 群聊撤回和修改 | 单聊、聊天室已覆盖，群聊缺少对应 QA 操作入口。 |
| P2 | `GROUP-022` 获取 / 设置群成员名片 | 群成员资料展示常用，但当前未找到 namecard 调用入口。 |
| P2 | `GROUP-031` 群组自定义属性管理 | 当前仅支持群成员属性，缺少群组属性增删改查入口。 |
| P2 | `MSG-025` 至 `MSG-038` 扩展消息能力 | 转发、引用、搜索、翻译、输入状态、Thread、流式消息、本地历史 / 本地更新 / 本地删除、流量统计等均未完整覆盖。 |

## 9. 覆盖统计

统计日期：2026-06-07。

统计口径：

- 官网功能总数按本文件中 `LOGIN`、`USER`、`MSG`、`CONV`、`GROUP`、`ROOM`、`PUSH` 表格的 Case 行计数，基准为 Android SDK 官网侧边栏功能页和概述页中可独立验证的客户端 / 服务端能力。
- `控制台/服务端` 项计入官网功能总数，但不计入客户端覆盖率分母。
- 本地覆盖总数 = `已实现` + `部分实现`。`部分实现` 代表本地存在真实 SDK 调用或回调入口，但覆盖范围未达到官网能力完整口径。

| 指标 | 数值 |
| --- | ---: |
| 官网功能总数 | 169 |
| 控制台/服务端功能数 | 12 |
| 客户端功能总数 | 157 |
| 已实现功能数 | 111 |
| 部分实现功能数 | 15 |
| 未实现客户端功能数 | 31 |
| 本地实现覆盖总数 | 126 |
| 功能覆盖率 | 80.25% |

分模块统计：

| 模块 | 官网功能数 |
| --- | ---: |
| 接入与登录 | 14 |
| 用户、联系人与 Presence | 22 |
| 消息管理 | 38 |
| 会话管理 | 18 |
| 群组管理 | 40 |
| 聊天室管理 | 27 |
| 离线推送 | 10 |

分模块客户端覆盖率：

| 模块 | 总 Case | 覆盖 Case | 覆盖率 |
| --- | ---: | ---: | ---: |
| 接入与登录 | 9 | 7 | 77.78% |
| 用户、联系人与 Presence | 22 | 21 | 95.45% |
| 消息管理 | 37 | 25 | 67.57% |
| 会话管理 | 18 | 12 | 66.67% |
| 群组管理 | 35 | 31 | 88.57% |
| 聊天室管理 | 26 | 25 | 96.15% |
| 离线推送 | 10 | 5 | 50.00% |
| 总数 | 157 | 126 | 80.25% |
