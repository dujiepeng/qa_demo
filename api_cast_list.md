# qa_demo 真实 SDK API 覆盖清单

## 统计说明

- 统计日期：2026-06-09。
- SDK 基准：`im_flutter_sdk-4.19.1`，来源为本机 pub cache 中 `lib/im_flutter_sdk.dart` 导出的 manager、`EMMessage`、`EMConversation`、`EMOptions`。
- 统计对象：`qa_demo/lib` 中对真实 SDK API 的静态调用。测试文件、注入 callback、mock、typedef 不计入覆盖证据。
- “真实 API”口径：会触达 SDK/native 或构造 SDK请求对象的公开方法，包括 `EMClient`、各 Manager、`EMMessage` 工厂和实例方法、`EMConversation` 实例方法、`EMOptions` 初始化/推送配置方法。
- 不计入口径：model 字段、枚举、纯数据 `toJson` / `fromJson` / `toString` / `copyWith`、私有方法、SDK 内部 native callback 分发函数、SDK 内部返回对象构造。
- 覆盖判断：只要 `lib` 中存在该 API 的真实调用或 tear-off 并可追溯到源码位置，即记为已覆盖；不会判断运行时服务端权限、厂商推送控制台或套餐是否已开通。
- “是否本地逻辑”按 SDK 注释和调用语义标注：`本地` 表示只影响本地缓存 / 数据库 / handler 注册表；`服务端` 表示会请求或变更服务端数据；`服务端+本地` 表示同时变更服务端和本地状态；`服务端资源` 表示下载或上传服务端文件 / 附件；`服务端/推送服务`、`服务端/翻译服务` 表示走对应服务；`构造本地对象`、`本地对象属性`、`配置构造` 表示不直接请求业务服务端；`可选：本地/服务端` 表示由参数决定。
- 说明：这是 API 调用覆盖率，不等同于官网功能 case 覆盖率；一个功能可能调用多个 API，一个 API 也可能支撑多个功能。

## 总览

| 指标 | 数值 |
| --- | ---: |
| API 总数 | 320 |
| 已覆盖 API 数 | 221 |
| 未覆盖 API 数 | 99 |
| API 覆盖率 | 69.06% |

## 分模块覆盖率

| 模块 | SDK 类 | API 总数 | 已覆盖 | 未覆盖 | 覆盖率 |
| --- | --- | ---: | ---: | ---: | ---: |
| 客户端与登录 | `EMClient` | 42 | 14 | 28 | 33.33% |
| 消息管理 | `EMChatManager` | 61 | 44 | 17 | 72.13% |
| 群组管理 | `EMGroupManager` | 59 | 53 | 6 | 89.83% |
| 聊天室管理 | `EMChatRoomManager` | 36 | 32 | 4 | 88.89% |
| 联系人管理 | `EMContactManager` | 24 | 16 | 8 | 66.67% |
| Presence | `EMPresenceManager` | 9 | 7 | 2 | 77.78% |
| 离线推送 | `EMPushManager` | 18 | 15 | 3 | 83.33% |
| 用户属性 | `EMUserInfoManager` | 4 | 3 | 1 | 75.00% |
| Thread / 子区 | `EMChatThreadManager` | 16 | 16 | 0 | 100.00% |
| 消息对象工厂 / 实例方法 | `EMMessage` | 16 | 11 | 5 | 68.75% |
| 会话对象方法 | `EMConversation` | 25 | 9 | 16 | 36.00% |
| 初始化配置 | `EMOptions` | 10 | 1 | 9 | 10.00% |
| 总数 | - | 320 | 221 | 99 | 69.06% |

## 重点缺口

- `EMConversation`：已覆盖会话列表展示、整会话已读和子区本地会话消息加载；仍缺少单条已读、本地插入 / 更新 / 删除、会话扩展、置顶消息、本地+服务端删除等 API。
- `EMOptions`：仅覆盖 `withAppKey` 初始化；厂商推送开关、AppId 初始化等配置 API 未覆盖。
- `EMChatManager`：已覆盖发送、逐条转发发送、已读回执、撤回、修改、远端删除、反应、置顶、会话标记、服务端资源下载、合并消息详情、翻译与举报等核心 API；本地 handler / 本地搜索 / 本地统计 / 本地清理类非必要诊断项暂不补。
- `EMClient`：初始化、密码登录、退出、日志压缩、设备查询/踢设备、多设备 handler 注册 / 移除已覆盖；账号创建、token 登录 / 续期、动态设置项、kickAllDevices 等未覆盖。

## 未覆盖 API 对应功能明细

### 客户端与登录（EMClient）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `changeAppId` | 运行时切换 App ID | 本地 | 登录 / 设置 / 设备管理入口 |
| `changeAppKey` | 运行时切换 App Key | 本地 | 登录 / 设置 / 设备管理入口 |
| `clearConnectionEventHandlers` | 清空全部连接事件监听 | 本地：事件注册表 | 登录 / 设置 / 设备管理入口 |
| `clearMultiDeviceEventHandlers` | 清空全部多设备事件监听 | 本地：事件注册表 | 登录 / 设置 / 设备管理入口 |
| `createAccount` | 通过 SDK 创建 IM 用户账号 | 服务端 | 登录 / 设置 / 设备管理入口 |
| `getAccessToken` | 获取当前登录用户 access token | 服务端 | 登录 / 设置 / 设备管理入口 |
| `getConnectionEventHandler` | 按 ID 获取连接事件监听 | 本地：事件注册表 | 登录 / 设置 / 设备管理入口 |
| `getLoggedInDevicesFromServer` | 从服务端获取指定账号已登录设备列表（旧接口） | 服务端 | 登录 / 设置 / 设备管理入口 |
| `getMultiDeviceEventHandler` | 按 ID 获取多设备事件监听 | 本地：事件注册表 | 登录 / 设置 / 设备管理入口 |
| `isLoginBefore` | 判断本地是否曾经登录过 | 本地 | 登录 / 设置 / 设备管理入口 |
| `kickAllDevices` | 踢掉账号下所有其他设备 | 服务端 | 登录 / 设置 / 设备管理入口 |
| `login` | 通用登录接口，支持密码或 token 登录模式 | 服务端 | 登录 / 设置 / 设备管理入口 |
| `loginWithAgoraToken` | 使用 Agora token 登录 | 服务端 | 登录 / 设置 / 设备管理入口 |
| `loginWithToken` | 使用用户 token 登录 | 服务端 | 登录 / 设置 / 设备管理入口 |
| `renewAgoraToken` | 续期 Agora token | 服务端 | 登录 / 设置 / 设备管理入口 |
| `updateAutoAcceptFriendInvitationSetting` | 更新是否自动接受好友邀请 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateAutoAcceptGroupInvitationSetting` | 更新是否自动接受群邀请 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateAutoDownloadAttachmentThumbnailSetting` | 更新是否自动下载附件缩略图 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateDeleteMessagesWhenLeaveGroupSetting` | 更新退群时是否删除群消息配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateDeleteMessageWhenLeaveRoomSetting` | 更新退出聊天室时是否删除聊天室消息配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateDeliveryAckSetting` | 更新是否需要发送送达回执配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateLoginExtensionInfoSetting` | 更新登录扩展信息配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateMessagesReceiveCallbackIncludeSendSetting` | 更新消息接收回调是否包含自己发送的消息 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateRegradeMessagesAsReadSetting` | 更新收到消息是否标记为已读配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateRequireAckSetting` | 更新是否需要已读回执配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateRoomOwnerCanLeaveSetting` | 更新聊天室所有者是否可退出聊天室配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateSortMessageByServerTimeSetting` | 更新消息是否按服务端时间排序配置 | 本地 | 登录 / 设置 / 设备管理入口 |
| `updateUsingHttpsOnlySetting` | 更新是否仅使用 HTTPS 配置 | 本地 | 登录 / 设置 / 设备管理入口 |

### 消息管理（EMChatManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `clearAllMessageEvents` | 清空全部消息发送状态监听 | 本地：发送状态回调注册 | 本地非必要，暂不补 |
| `clearEventHandlers` | 清空全部聊天事件监听 | 本地：事件注册表 | 本地非必要，暂不补 |
| `clearMessageEvent` | 清空消息发送状态监听集合 | 本地：发送状态回调注册 | 本地非必要，暂不补 |
| `deleteAllMessageAndConversation` | 删除本地全部消息和会话 | 可选：本地/服务端 | 破坏性清理 / 本地非必要，暂不补 |
| `deleteConversation` | 删除本地会话，可选择是否删除本地消息 | 本地 | 本地非必要，暂不补 |
| `deleteMessagesBefore` | 按时间删除本地历史消息 | 本地 | 本地非必要，暂不补 |
| `getAllMessageCount` | 获取本地全部消息数量 | 本地 | 本地非必要，暂不补 |
| `getEventHandler` | 按 ID 获取聊天事件监听 | 本地：事件注册表 | 本地非必要，暂不补 |
| `getUnreadMessageCount` | 获取本地全部未读消息数 | 本地 | 本地非必要，暂不补 |
| `loadConversationMessagesWithKeyword` | 按关键字跨会话搜索本地消息 | 本地 | 本地非必要，暂不补 |
| `loadMessagesWithIds` | 按消息 ID 批量加载本地消息 | 本地 | 本地非必要，暂不补 |
| `loadMessagesWithKeyword` | 按关键字加载本地消息 | 本地 | 本地非必要，暂不补 |
| `markAllConversationsAsRead` | 将全部会话标记为已读 | 本地 | 本地非必要，暂不补 |
| `removeMessageEvent` | 移除消息发送状态监听 | 本地：发送状态回调注册 | 本地非必要，暂不补 |
| `searchMsgFromDB` | 按条件搜索本地消息 | 本地 | 本地非必要，暂不补 |
| `searchMsgsByOptions` | 按高级条件搜索消息 | 本地 | 本地非必要，暂不补 |
| `updateMessage` | 更新本地消息 | 本地 | 本地非必要，暂不补 |

### 群组管理（EMGroupManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `clearAllGroupsFromLocal` | 清空本地群组缓存 | 本地 | 群组页 / 群成员页补充入口 |
| `clearEventHandlers` | 清空全部群组事件监听 | 本地：事件注册表 | 群组页 / 群成员页补充入口 |
| `getEventHandler` | 按 ID 获取群组事件监听 | 本地：事件注册表 | 群组页 / 群成员页补充入口 |
| `getGroupWithId` | 从本地获取指定群组 | 本地 | 群组页 / 群成员页补充入口 |
| `getJoinedGroups` | 从本地获取已加入群组列表 | 本地 | 群组页 / 群成员页补充入口 |
| `removeMemberAttributes` | 删除群成员自定义属性 | 服务端 | 群组页 / 群成员页补充入口 |

### 聊天室管理（EMChatRoomManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `clearEventHandlers` | 清空全部聊天室事件监听 | 本地：事件注册表 | 聊天室页 / 成员页补充入口 |
| `getChatRoomWithId` | 从本地获取指定聊天室 | 本地 | 聊天室页 / 成员页补充入口 |
| `getEventHandler` | 按 ID 获取聊天室事件监听 | 本地：事件注册表 | 聊天室页 / 成员页补充入口 |
| `removeEventHandler` | 移除聊天室事件监听 | 本地：事件注册表 | 聊天室页 / 成员页补充入口 |

### 联系人管理（EMContactManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `clearEventHandlers` | 清空全部联系人事件监听 | 本地：事件注册表 | 联系人页补充入口 |
| `getAllContactIds` | 从本地获取联系人 ID 列表 | 本地 | 联系人页补充入口 |
| `getAllContacts` | 获取联系人列表（兼容接口） | 本地 | 联系人页补充入口 |
| `getAllContactsFromDB` | 从本地数据库获取联系人列表 | 本地 | 联系人页补充入口 |
| `getBlockIds` | 从本地获取黑名单 ID 列表 | 本地 | 联系人页补充入口 |
| `getBlockListFromDB` | 从本地数据库获取黑名单 | 本地 | 联系人页补充入口 |
| `getContact` | 获取单个联系人详情 | 本地 | 联系人页补充入口 |
| `getEventHandler` | 按 ID 获取联系人事件监听 | 本地：事件注册表 | 联系人页补充入口 |

### Presence（EMPresenceManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `clearEventHandlers` | 清空全部 Presence 事件监听 | 本地：事件注册表 | 补充 QA 入口 |
| `getEventHandler` | 按 ID 获取 Presence 事件监听 | 本地：事件注册表 | 补充 QA 入口 |

### 离线推送（EMPushManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `updateAPNsDeviceToken` | 更新 APNs 设备 token（旧接口） | 服务端/推送服务 | 平台 token 旧接口，已有通用 `bindDeviceToken`，非必须暂不补 |
| `updateFCMPushToken` | 更新 FCM 设备 token（旧接口） | 服务端/推送服务 | 平台 token 旧接口，已有通用 `bindDeviceToken`，非必须暂不补 |
| `updateHMSPushToken` | 更新华为 HMS 设备 token（旧接口） | 服务端/推送服务 | 平台 token 旧接口，已有通用 `bindDeviceToken`，非必须暂不补 |

### 用户属性（EMUserInfoManager）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `clearUserInfoCache` | 清空用户属性缓存 | 本地 | 补充 QA 入口 |

### 消息对象工厂 / 实例方法（EMMessage）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `chatroomMessagePriority` | 设置聊天室消息优先级 | 本地对象属性 | 消息类型 / 消息详情工具入口 |
| `chatThread` | 获取消息所属 Thread 信息 | 本地对象属性 | 消息类型 / 消息详情工具入口 |
| `createReceiveMessage` | 创建接收方向消息对象 | 构造本地对象 | 消息类型 / 消息详情工具入口 |
| `groupAckCount` | 获取群消息已读回执数量 | 本地对象属性 | 消息类型 / 消息详情工具入口 |
| `reactionList` | 获取消息 reaction 列表 | 本地对象属性 | 消息类型 / 消息详情工具入口 |

### 会话对象方法（EMConversation）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `appendMessage` | 向会话尾部追加本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `deleteAllMessages` | 删除会话内全部本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `deleteMessage` | 删除单条本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `deleteMessageByIds` | 按 ID 批量删除本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `deleteMessagesWithTs` | 按时间段删除本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `getLocalMessageCount` | 按条件获取本地消息数量 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `lastReceivedMessage` | 获取对方发来的最后一条消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `loadMessagesFromTime` | 按时间范围加载本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `loadMessagesWithKeyword` | 按关键字加载会话本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `loadMessagesWithMsgType` | 按消息类型加载本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `loadPinnedMessages` | 加载会话内置顶消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `markMessageAsRead` | 将指定消息标记为已读 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `messagesCount` | 获取会话内消息总数 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `searchMsgsByOptions` | 按高级选项搜索会话消息 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `setExt` | 设置会话扩展字段 | 本地 | 会话详情 / 本地消息 QA 面板 |
| `updateMessage` | 更新会话内本地消息 | 本地 | 会话详情 / 本地消息 QA 面板 |

### 初始化配置（EMOptions）

| API | 对应功能 | 是否本地逻辑 | 建议入口 |
| --- | --- | --- | --- |
| `enableAPNs` | 启用 APNs 推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableFCM` | 启用 FCM 推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableHonorPush` | 启用荣耀推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableHWPush` | 启用华为推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableMeiZuPush` | 启用魅族推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableMiPush` | 启用小米推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableOppoPush` | 启用 OPPO 推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `enableVivoPush` | 启用 vivo 推送配置 | 配置构造 | 服务器设置 / 推送厂商配置入口 |
| `withAppId` | 使用 App ID 构造 SDK 初始化配置 | 配置构造 | 登录初始化配置入口 |

## 全量 API 覆盖明细

### 客户端与登录（EMClient）

覆盖：14/42（33.33%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `addConnectionEventHandler` | 已覆盖 | 本地：事件注册表 | lib/common/utils/chat_event_widget.dart:28<br>lib/pages/home_page.dart:250 |
| `addMultiDeviceEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/home_page.dart:85 |
| `changeAppId` | 未覆盖 | 本地 | - |
| `changeAppKey` | 未覆盖 | 本地 | - |
| `clearConnectionEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `clearMultiDeviceEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `compressLogs` | 已覆盖 | 本地 | lib/common/utils/log_file_helper.dart:40 |
| `createAccount` | 未覆盖 | 服务端 | - |
| `fetchLoggedInDevices` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:11 |
| `getAccessToken` | 未覆盖 | 服务端 | - |
| `getConnectionEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `getCurrentDeviceId` | 已覆盖 | 本地 | lib/common/widgets/common_dialogs.dart:12<br>lib/common/widgets/info_dialog.dart:43 |
| `getCurrentUserId` | 已覆盖 | 本地 | lib/common/widgets/common_dialogs.dart:11<br>lib/common/widgets/info_dialog.dart:42<br>lib/pages/chatroom/room_members_page.dart:132 |
| `getLoggedInDevicesFromServer` | 未覆盖 | 服务端 | - |
| `getMultiDeviceEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `init` | 已覆盖 | 本地 | lib/common/mixins/login_logic_mixin.dart:11 |
| `isConnected` | 已覆盖 | 本地 | lib/pages/home_page.dart:246 |
| `isLoginBefore` | 未覆盖 | 本地 | - |
| `kickAllDevices` | 未覆盖 | 服务端 | - |
| `kickDevice` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:27 |
| `login` | 未覆盖 | 服务端 | - |
| `loginWithAgoraToken` | 未覆盖 | 服务端 | - |
| `loginWithPassword` | 已覆盖 | 服务端 | lib/common/mixins/login_logic_mixin.dart:136 |
| `loginWithToken` | 未覆盖 | 服务端 | - |
| `logout` | 已覆盖 | 服务端 | lib/common/mixins/login_logic_mixin.dart:134<br>lib/common/session_scope.dart:57 |
| `removeConnectionEventHandler` | 已覆盖 | 本地：事件注册表 | lib/common/utils/chat_event_widget.dart:23<br>lib/pages/home_page.dart:60 |
| `removeMultiDeviceEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/home_page.dart:74 |
| `renewAgoraToken` | 未覆盖 | 服务端 | - |
| `startCallback` | 已覆盖 | 本地 | lib/common/utils/chat_event_widget.dart:56<br>lib/pages/home_page.dart:53 |
| `updateAutoAcceptFriendInvitationSetting` | 未覆盖 | 本地 | - |
| `updateAutoAcceptGroupInvitationSetting` | 未覆盖 | 本地 | - |
| `updateAutoDownloadAttachmentThumbnailSetting` | 未覆盖 | 本地 | - |
| `updateDeleteMessagesWhenLeaveGroupSetting` | 未覆盖 | 本地 | - |
| `updateDeleteMessageWhenLeaveRoomSetting` | 未覆盖 | 本地 | - |
| `updateDeliveryAckSetting` | 未覆盖 | 本地 | - |
| `updateLoginExtensionInfoSetting` | 未覆盖 | 本地 | - |
| `updateMessagesReceiveCallbackIncludeSendSetting` | 未覆盖 | 本地 | - |
| `updateRegradeMessagesAsReadSetting` | 未覆盖 | 本地 | - |
| `updateRequireAckSetting` | 未覆盖 | 本地 | - |
| `updateRoomOwnerCanLeaveSetting` | 未覆盖 | 本地 | - |
| `updateSortMessageByServerTimeSetting` | 未覆盖 | 本地 | - |
| `updateUsingHttpsOnlySetting` | 未覆盖 | 本地 | - |

### 消息管理（EMChatManager）

覆盖：44/61（72.13%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `addEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/chatroom/room_page.dart:244<br>lib/pages/conversation/conversation_list_page.dart:60<br>lib/pages/group/group_page.dart:178 |
| `addMessageEvent` | 已覆盖 | 本地：发送状态回调注册 | lib/pages/chatroom/room_page.dart:232<br>lib/pages/group/group_page.dart:166<br>lib/pages/single/single_chat_page.dart:78 |
| `addReaction` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:350 |
| `addRemoteAndLocalConversationsMark` | 已覆盖 | 服务端+本地 | lib/pages/conversation/conversation_list_page.dart:298 |
| `clearAllMessageEvents` | 未覆盖 | 本地：发送状态回调注册 | - |
| `clearEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `clearMessageEvent` | 未覆盖 | 本地：发送状态回调注册 | - |
| `deleteAllMessageAndConversation` | 未覆盖 | 可选：本地/服务端 | - |
| `deleteConversation` | 未覆盖 | 本地 | - |
| `deleteMessagesBefore` | 未覆盖 | 本地 | - |
| `deleteRemoteAndLocalConversationsMark` | 已覆盖 | 服务端+本地 | lib/pages/conversation/conversation_list_page.dart:323 |
| `deleteRemoteConversation` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:405 |
| `deleteRemoteMessagesBefore` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:741 |
| `deleteRemoteMessagesWithIds` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:724<br>lib/pages/single/single_chat_page.dart:421 |
| `downloadAttachment` | 已覆盖 | 服务端资源 | lib/pages/single/single_chat_page.dart:678 |
| `downloadMessageAttachmentInCombine` | 已覆盖 | 服务端资源 | lib/pages/single/single_chat_page.dart:719 |
| `downloadMessageThumbnailInCombine` | 已覆盖 | 服务端资源 | lib/pages/single/single_chat_page.dart:741 |
| `downloadThumbnail` | 已覆盖 | 服务端资源 | lib/pages/single/single_chat_page.dart:697 |
| `fetchCombineMessageDetail` | 已覆盖 | 服务端资源 | lib/pages/single/single_chat_page.dart:762 |
| `fetchConversation` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:423（old / 旧接口） |
| `fetchConversationListFromServer` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:406（old / 旧接口） |
| `fetchConversationsByOptions` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:185 |
| `fetchGroupAcks` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:669 |
| `fetchHistoryMessages` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:1042（old / 旧接口） |
| `fetchHistoryMessagesByOption` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:758 |
| `fetchPinnedConversations` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:448 |
| `fetchPinnedMessages` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:811 |
| `fetchReactionDetail` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:813 |
| `fetchReactionList` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:788 |
| `fetchSupportedLanguages` | 已覆盖 | 服务端/翻译服务 | lib/pages/single/single_chat_page.dart:837 |
| `getAllMessageCount` | 未覆盖 | 本地 | - |
| `getConversation` | 已覆盖 | 本地 | lib/pages/single/single_chat_page.dart:582 |
| `getConversationsFromServer` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:391（old / 旧接口） |
| `getEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `getThreadConversation` | 已覆盖 | 本地 | lib/pages/thread/chat_thread_page.dart:480 |
| `getUnreadMessageCount` | 未覆盖 | 本地 | - |
| `importMessages` | 已覆盖 | 本地 | lib/pages/single/single_chat_page.dart:570 |
| `loadAllConversations` | 已覆盖 | 本地 | lib/pages/conversation/conversation_list_page.dart:211 |
| `loadConversationMessagesWithKeyword` | 未覆盖 | 本地 | - |
| `loadMessage` | 已覆盖 | 本地 | lib/pages/single/single_chat_page.dart:307 |
| `loadMessagesWithIds` | 未覆盖 | 本地 | - |
| `loadMessagesWithKeyword` | 未覆盖 | 本地 | - |
| `markAllConversationsAsRead` | 未覆盖 | 本地 | - |
| `modifyMessage` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:707<br>lib/pages/single/single_chat_page.dart:446 |
| `pinConversation` | 已覆盖 | 服务端+本地 | lib/pages/conversation/conversation_list_page.dart:369 |
| `pinMessage` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:376 |
| `recallMessage` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:599<br>lib/pages/single/single_chat_page.dart:475 |
| `removeEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/conversation/conversation_list_page.dart:77<br>lib/pages/home_page.dart:63 |
| `removeMessageEvent` | 未覆盖 | 本地：发送状态回调注册 | - |
| `removeReaction` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:356 |
| `reportMessage` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:908 |
| `resendMessage` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:546 |
| `searchMsgFromDB` | 未覆盖 | 本地 | - |
| `searchMsgsByOptions` | 未覆盖 | 本地 | - |
| `sendConversationReadAck` | 已覆盖 | 服务端 | lib/pages/conversation/conversation_list_page.dart:445 |
| `sendGroupMessageReadAck` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:651 |
| `sendMessage` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:901（聊天室发送 / 转发共用默认实现）<br>lib/pages/group/group_page.dart:530（群聊逐条转发）<br>lib/pages/group/group_page.dart:700（群聊发送 / 合并转发共用默认实现）<br>lib/pages/single/single_chat_page.dart:660（单聊发送 / 转发共用默认实现） |
| `sendMessageReadAck` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:324 |
| `translateMessage` | 已覆盖 | 服务端/翻译服务 | lib/pages/single/single_chat_page.dart:873 |
| `unpinMessage` | 已覆盖 | 服务端 | lib/pages/single/single_chat_page.dart:398 |
| `updateMessage` | 未覆盖 | 本地 | - |

### 群组管理（EMGroupManager）

覆盖：53/59（89.83%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `acceptInvitation` | 已覆盖 | 服务端 | lib/pages/group/group_list_page.dart:120 |
| `acceptJoinApplication` | 已覆盖 | 服务端 | lib/pages/group/group_list_page.dart:164 |
| `addAdmin` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:355 |
| `addAllowList` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:388 |
| `addEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/group/group_list_page.dart:39<br>lib/pages/group/group_page.dart:246<br>lib/pages/home_page.dart:131 |
| `addMembers` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:140 |
| `blockGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:386 |
| `blockMembers` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:422 |
| `changeGroupDescription` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:417（old / 旧接口） |
| `changeGroupName` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:409（old / 旧接口） |
| `changeOwner` | 已覆盖 | 服务端 | lib/pages/group/group_change_owner_page.dart:225 |
| `clearAllGroupsFromLocal` | 未覆盖 | 本地 | - |
| `clearEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `createGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:364 |
| `declineInvitation` | 已覆盖 | 服务端 | lib/pages/group/group_list_page.dart:142 |
| `declineJoinApplication` | 已覆盖 | 服务端 | lib/pages/group/group_list_page.dart:188 |
| `destroyGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:378 |
| `downloadGroupSharedFile` | 已覆盖 | 服务端资源 | lib/pages/group/group_page.dart:473 |
| `fetchAllowListFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_white_list_page.dart:45 |
| `fetchAnnouncementFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:402 |
| `fetchBlockListFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:810 |
| `fetchGroupFileListFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:438 |
| `fetchGroupInfoFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_admins_page.dart:78<br>lib/pages/group/group_change_owner_page.dart:144<br>lib/pages/group/group_page.dart:325 |
| `fetchGroupMembersInfo` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:545 |
| `fetchJoinedGroupCount` | 已覆盖 | 服务端 | lib/pages/group/group_list_page.dart:304 |
| `fetchJoinedGroupsFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_list_page.dart:231 |
| `fetchMemberAttributes` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:440 |
| `fetchMemberListFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_change_owner_page.dart:156<br>lib/pages/group/group_members_page.dart:345 |
| `fetchMembersAttributes` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:502 |
| `fetchMuteListFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_mute_list_page.dart:62 |
| `fetchPublicGroupsFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:487 |
| `getEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `getGroupWithId` | 未覆盖 | 本地 | - |
| `getJoinedGroups` | 未覆盖 | 本地 | - |
| `inviterUser` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:472（old / 旧接口） |
| `isMemberInAllowListFromServer` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:498 |
| `isMemberInGroupMuteList` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:508 |
| `joinPublicGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:333 |
| `leaveGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:756 |
| `muteAllMembers` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:1233 |
| `muteMembers` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:372 |
| `removeAdmin` | 已覆盖 | 服务端 | lib/pages/group/group_admins_page.dart:144 |
| `removeAllowList` | 已覆盖 | 服务端 | lib/pages/group/group_white_list_page.dart:114 |
| `removeEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/group/group_list_page.dart:108<br>lib/pages/home_page.dart:71 |
| `removeGroupSharedFile` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:485 |
| `removeMemberAttributes` | 未覆盖 | 服务端 | - |
| `removeMembers` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:405 |
| `requestToJoinPublicGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:341 |
| `setMemberAttributes` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:1585 |
| `unblockGroup` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:394 |
| `unblockMembers` | 已覆盖 | 服务端 | lib/pages/group/group_members_page.dart:871 |
| `unMuteAllMembers` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:1235 |
| `unMuteMembers` | 已覆盖 | 服务端 | lib/pages/group/group_mute_list_page.dart:173 |
| `updateGroupAnnouncement` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:948 |
| `updateGroupAvatar` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:412 |
| `updateGroupDesc` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:942 |
| `updateGroupExtension` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:423 |
| `updateGroupName` | 已覆盖 | 服务端 | lib/pages/group/group_page.dart:936 |
| `uploadGroupSharedFile` | 已覆盖 | 服务端资源 | lib/pages/group/group_page.dart:450 |

### 聊天室管理（EMChatRoomManager）

覆盖：32/36（88.89%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `addAttributes` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:1316 |
| `addChatRoomAdmin` | 已覆盖 | 服务端 | lib/pages/chatroom/room_members_page.dart:273 |
| `addEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/chatroom/room_page.dart:277 |
| `addMembersToChatRoomAllowList` | 已覆盖 | 服务端 | lib/pages/chatroom/room_members_page.dart:305 |
| `blockChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_members_page.dart:325 |
| `changeChatRoomDescription` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:924 |
| `changeChatRoomName` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:917 |
| `changeOwner` | 已覆盖 | 服务端 | lib/pages/chatroom/room_change_owner_page.dart:159 |
| `clearEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `createChatRoom` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:213 |
| `destroyChatRoom` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:1089 |
| `fetchChatRoomAllowListFromServer` | 已覆盖 | 服务端 | lib/pages/chatroom/room_white_list_page.dart:44 |
| `fetchChatRoomAnnouncement` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:238 |
| `fetchChatRoomAttributes` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:1129 |
| `fetchChatRoomBlockList` | 已覆盖 | 服务端 | lib/pages/chatroom/room_block_list_page.dart:69 |
| `fetchChatRoomInfoFromServer` | 已覆盖 | 服务端 | lib/common/widgets/info_dialog.dart:48<br>lib/pages/chatroom/room_admins_page.dart:43<br>lib/pages/chatroom/room_change_owner_page.dart:135 |
| `fetchChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_change_owner_page.dart:147<br>lib/pages/chatroom/room_members_page.dart:264<br>lib/pages/chatroom/room_page.dart:840 |
| `fetchChatRoomMuteList` | 已覆盖 | 服务端 | lib/pages/chatroom/room_mute_list_page.dart:59 |
| `fetchPublicChatRoomsFromServer` | 已覆盖 | 服务端 | lib/pages/chatroom/room_list_page.dart:59 |
| `getChatRoomWithId` | 未覆盖 | 本地 | - |
| `getEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `isMemberInChatRoomAllowList` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:248 |
| `isMemberInChatRoomMuteList` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:258 |
| `joinChatRoom` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:768 |
| `leaveChatRoom` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:755 |
| `muteAllChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:1000 |
| `muteChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_members_page.dart:289 |
| `removeAttributes` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:1107 |
| `removeChatRoomAdmin` | 已覆盖 | 服务端 | lib/pages/chatroom/room_admins_page.dart:110 |
| `removeChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_members_page.dart:346 |
| `removeEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `removeMembersFromChatRoomAllowList` | 已覆盖 | 服务端 | lib/pages/chatroom/room_white_list_page.dart:111 |
| `unBlockChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_block_list_page.dart:183 |
| `unMuteAllChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:1004 |
| `unMuteChatRoomMembers` | 已覆盖 | 服务端 | lib/pages/chatroom/room_mute_list_page.dart:165 |
| `updateChatRoomAnnouncement` | 已覆盖 | 服务端 | lib/pages/chatroom/room_page.dart:928 |

### 联系人管理（EMContactManager）

覆盖：16/24（66.67%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `acceptInvitation` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:91 |
| `addContact` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:233 |
| `addEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/home_page.dart:192<br>lib/pages/single/single_chat_list_page.dart:38 |
| `addUserToBlockList` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:36 |
| `clearEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `declineInvitation` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:114 |
| `deleteContact` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:251 |
| `fetchAllContactIds` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:304 |
| `fetchAllContacts` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:4 |
| `fetchBlockIds` | 已覆盖 | 服务端 | lib/pages/single/black_list_page.dart:48 |
| `fetchContacts` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:315 |
| `getAllContactIds` | 未覆盖 | 本地 | - |
| `getAllContacts` | 未覆盖 | 本地 | - |
| `getAllContactsFromDB` | 未覆盖 | 本地 | - |
| `getAllContactsFromServer` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:329（old / 旧接口） |
| `getBlockIds` | 未覆盖 | 本地 | - |
| `getBlockListFromDB` | 未覆盖 | 本地 | - |
| `getBlockListFromServer` | 已覆盖 | 服务端 | lib/pages/single/single_chat_list_page.dart:344（old / 旧接口） |
| `getContact` | 未覆盖 | 本地 | - |
| `getEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `getSelfIdsOnOtherPlatform` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:8 |
| `removeEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/home_page.dart:68 |
| `removeUserFromBlockList` | 已覆盖 | 服务端 | lib/pages/single/black_list_page.dart:52 |
| `setContactRemark` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:43 |

### Presence（EMPresenceManager）

覆盖：7/9（77.78%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `addEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/single/contact_presence_page.dart:98 |
| `clearEventHandlers` | 未覆盖 | 本地：事件注册表 | - |
| `fetchPresenceStatus` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:65 |
| `fetchSubscribedMembers` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:50 |
| `getEventHandler` | 未覆盖 | 本地：事件注册表 | - |
| `publishPresence` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:79 |
| `removeEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/single/contact_presence_page.dart:82 |
| `subscribe` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:54 |
| `unsubscribe` | 已覆盖 | 服务端 | lib/pages/single/contact_api.dart:61 |

### 离线推送（EMPushManager）

覆盖：15/18（83.33%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `bindDeviceToken` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:342 |
| `fetchConversationSilentMode` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:382 |
| `fetchPreferredNotificationLanguage` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:425 |
| `fetchPushConfigsFromServer` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:406 |
| `fetchSilentModeForAll` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:353 |
| `fetchSilentModeForConversations` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:394 |
| `getPushTemplate` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:414 |
| `removeConversationSilentMode` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:372 |
| `setConversationSilentMode` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:361 |
| `setPreferredNotificationLanguage` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:418 |
| `setPushTemplate` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:410 |
| `setSilentModeForAll` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:349 |
| `syncConversationsSilentMode` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:389 |
| `updateAPNsDeviceToken` | 未覆盖 | 服务端/推送服务 | 平台 token 旧接口，已有通用 `bindDeviceToken`，非必须暂不补 |
| `updateFCMPushToken` | 未覆盖 | 服务端/推送服务 | 平台 token 旧接口，已有通用 `bindDeviceToken`，非必须暂不补 |
| `updateHMSPushToken` | 未覆盖 | 服务端/推送服务 | 平台 token 旧接口，已有通用 `bindDeviceToken`，非必须暂不补 |
| `updatePushDisplayStyle` | 已覆盖 | 服务端/推送服务 | lib/mobile/push_settings_page_mobile.dart:400 |
| `updatePushNickname` | 已覆盖 | 服务端/推送服务 | lib/mobile/my_page_mobile.dart:17 |

### 用户属性（EMUserInfoManager）

覆盖：3/4（75.00%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `clearUserInfoCache` | 未覆盖 | 本地 | - |
| `fetchOwnInfo` | 已覆盖 | 服务端 | lib/mobile/my_user_profile_page_mobile.dart:22 |
| `fetchUserInfoById` | 已覆盖 | 服务端 | lib/mobile/user_info_lookup_page_mobile.dart:75 |
| `updateUserInfo` | 已覆盖 | 服务端 | lib/mobile/my_user_profile_page_mobile.dart:109 |

### Thread / 子区（EMChatThreadManager）

覆盖：16/16（100.00%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `addEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/thread/chat_thread_page.dart:227 |
| `clearEventHandlers` | 已覆盖 | 本地：事件注册表 | lib/pages/thread/chat_thread_page.dart:276 |
| `createChatThread` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:327 |
| `destroyChatThread` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:419 |
| `fetchChatThread` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:339 |
| `fetchChatThreadMembers` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:349 |
| `fetchChatThreadsWithParentId` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:362 |
| `fetchJoinedChatThreads` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:370 |
| `fetchJoinedChatThreadsWithParentId` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:380 |
| `fetchLatestMessageWithChatThreads` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:393 |
| `getEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/thread/chat_thread_page.dart:267 |
| `joinChatThread` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:403 |
| `leaveChatThread` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:411 |
| `removeEventHandler` | 已覆盖 | 本地：事件注册表 | lib/pages/thread/chat_thread_page.dart:252 |
| `removeMemberFromChatThread` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:430 |
| `updateChatThreadName` | 已覆盖 | 服务端 | lib/pages/thread/chat_thread_page.dart:444 |

### 消息对象工厂 / 实例方法（EMMessage）

覆盖：11/16（68.75%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `chatroomMessagePriority` | 未覆盖 | 本地对象属性 | - |
| `chatThread` | 未覆盖 | 本地对象属性 | - |
| `createCmdSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:75<br>lib/pages/group/group_page.dart:61<br>lib/pages/single/single_chat_page.dart:28 |
| `createCombineSendMessage` | 已覆盖 | 构造本地对象 | lib/common/utils/message_forward_helper.dart:79（合并转发：目标 ID、消息 ID 列表、标题、摘要、兼容文本） |
| `createCustomSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:1236<br>lib/pages/group/group_page.dart:1057<br>lib/pages/single/single_chat_page.dart:715 |
| `createFileSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:1215<br>lib/pages/group/group_page.dart:1036<br>lib/pages/single/single_chat_page.dart:678 |
| `createImageSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:1178<br>lib/pages/group/group_page.dart:999<br>lib/pages/single/single_chat_page.dart:613 |
| `createLocationSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:1225<br>lib/pages/group/group_page.dart:1046<br>lib/pages/single/single_chat_page.dart:696 |
| `createReceiveMessage` | 未覆盖 | 构造本地对象 | - |
| `createSendMessage` | 已覆盖 | 构造本地对象 | lib/common/utils/message_forward_helper.dart:52（逐条转发：复用源消息 body，复制 ext 到新消息） |
| `createTxtSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:789<br>lib/pages/group/group_page.dart:598<br>lib/pages/single/single_chat_page.dart:549 |
| `createVideoSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:1190<br>lib/pages/group/group_page.dart:1011<br>lib/pages/single/single_chat_page.dart:635 |
| `createVoiceSendMessage` | 已覆盖 | 构造本地对象 | lib/pages/chatroom/room_page.dart:1204<br>lib/pages/group/group_page.dart:1025<br>lib/pages/single/single_chat_page.dart:658 |
| `groupAckCount` | 未覆盖 | 本地对象属性 | - |
| `pinInfo` | 已覆盖 | 本地对象属性 | lib/pages/single/single_chat_page.dart:309 |
| `reactionList` | 未覆盖 | 本地对象属性 | - |

### 会话对象方法（EMConversation）

覆盖：9/25（36.00%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `appendMessage` | 未覆盖 | 本地 | - |
| `deleteAllMessages` | 未覆盖 | 本地 | - |
| `deleteLocalAndServerMessages` | 已覆盖 | 服务端+本地 | lib/pages/conversation/conversation_list_page.dart:644 |
| `deleteLocalAndServerMessagesByTime` | 已覆盖 | 服务端+本地 | lib/pages/conversation/conversation_list_page.dart:697 |
| `deleteMessage` | 未覆盖 | 本地 | - |
| `deleteMessageByIds` | 未覆盖 | 本地 | - |
| `deleteMessagesWithTs` | 未覆盖 | 本地 | - |
| `getLocalMessageCount` | 未覆盖 | 本地 | - |
| `insertMessage` | 已覆盖 | 本地 | lib/pages/single/single_chat_page.dart:597 |
| `lastReceivedMessage` | 未覆盖 | 本地 | - |
| `latestMessage` | 已覆盖 | 本地 | lib/pages/conversation/conversation_list_page.dart:362 |
| `loadMessage` | 已覆盖 | 本地 | lib/pages/single/single_chat_page.dart:305 |
| `loadMessages` | 已覆盖 | 本地 | lib/pages/thread/chat_thread_page.dart:496 |
| `loadMessagesFromTime` | 未覆盖 | 本地 | - |
| `loadMessagesWithKeyword` | 未覆盖 | 本地 | - |
| `loadMessagesWithMsgType` | 未覆盖 | 本地 | - |
| `loadPinnedMessages` | 未覆盖 | 本地 | - |
| `markAllMessagesAsRead` | 已覆盖 | 本地 | lib/pages/conversation/conversation_list_page.dart:424 |
| `markMessageAsRead` | 未覆盖 | 本地 | - |
| `messagesCount` | 未覆盖 | 本地 | - |
| `remindType` | 已覆盖 | 服务端/推送服务 | lib/pages/conversation/conversation_list_page.dart:593 |
| `searchMsgsByOptions` | 未覆盖 | 本地 | - |
| `setExt` | 未覆盖 | 本地 | - |
| `unreadCount` | 已覆盖 | 本地 | lib/pages/conversation/conversation_list_page.dart:354 |
| `updateMessage` | 未覆盖 | 本地 | - |

### 初始化配置（EMOptions）

覆盖：1/10（10.00%）

| API | 状态 | 是否本地逻辑 | 证据 |
| --- | --- | --- | --- |
| `enableAPNs` | 未覆盖 | 配置构造 | - |
| `enableFCM` | 未覆盖 | 配置构造 | - |
| `enableHonorPush` | 未覆盖 | 配置构造 | - |
| `enableHWPush` | 未覆盖 | 配置构造 | - |
| `enableMeiZuPush` | 未覆盖 | 配置构造 | - |
| `enableMiPush` | 未覆盖 | 配置构造 | - |
| `enableOppoPush` | 未覆盖 | 配置构造 | - |
| `enableVivoPush` | 未覆盖 | 配置构造 | - |
| `withAppId` | 未覆盖 | 配置构造 | - |
| `withAppKey` | 已覆盖 | 配置构造 | lib/common/mixins/login_logic_mixin.dart:33 |
