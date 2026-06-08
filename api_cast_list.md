# qa_demo 真实 SDK API 覆盖清单

## 统计说明

- 统计日期：2026-06-08。
- SDK 基准：`im_flutter_sdk-4.19.1`，来源为本机 pub cache 中 `lib/im_flutter_sdk.dart` 导出的 manager、`EMMessage`、`EMConversation`、`EMOptions`。
- 统计对象：`qa_demo/lib` 中对真实 SDK API 的静态调用。测试文件、注入 callback、mock、typedef 不计入覆盖证据。
- “真实 API”口径：会触达 SDK/native 或构造 SDK请求对象的公开方法，包括 `EMClient`、各 Manager、`EMMessage` 工厂和实例方法、`EMConversation` 实例方法、`EMOptions` 初始化/推送配置方法。
- 不计入口径：model 字段、枚举、纯数据 `toJson` / `fromJson` / `toString` / `copyWith`、私有方法、SDK 内部 native callback 分发函数、SDK 内部返回对象构造。
- 覆盖判断：只要 `lib` 中存在该 API 的真实调用或 tear-off 并可追溯到源码位置，即记为已覆盖；不会判断运行时服务端权限、厂商推送控制台或套餐是否已开通。
- 说明：这是 API 调用覆盖率，不等同于官网功能 case 覆盖率；一个功能可能调用多个 API，一个 API 也可能支撑多个功能。

## 总览

| 指标 | 数值 |
| --- | ---: |
| API 总数 | 320 |
| 已覆盖 API 数 | 151 |
| 未覆盖 API 数 | 169 |
| API 覆盖率 | 47.19% |

## 分模块覆盖率

| 模块 | SDK 类 | API 总数 | 已覆盖 | 未覆盖 | 覆盖率 |
| --- | --- | ---: | ---: | ---: | ---: |
| 客户端与登录 | `EMClient` | 42 | 12 | 30 | 28.57% |
| 消息管理 | `EMChatManager` | 61 | 24 | 37 | 39.34% |
| 群组管理 | `EMGroupManager` | 59 | 38 | 21 | 64.41% |
| 聊天室管理 | `EMChatRoomManager` | 36 | 29 | 7 | 80.56% |
| 联系人管理 | `EMContactManager` | 24 | 12 | 12 | 50.00% |
| Presence | `EMPresenceManager` | 9 | 7 | 2 | 77.78% |
| 离线推送 | `EMPushManager` | 18 | 12 | 6 | 66.67% |
| 用户属性 | `EMUserInfoManager` | 4 | 3 | 1 | 75.00% |
| Thread / 子区 | `EMChatThreadManager` | 16 | 0 | 16 | 0.00% |
| 消息对象工厂 / 实例方法 | `EMMessage` | 16 | 9 | 7 | 56.25% |
| 会话对象方法 | `EMConversation` | 25 | 4 | 21 | 16.00% |
| 初始化配置 | `EMOptions` | 10 | 1 | 9 | 10.00% |
| 总数 | - | 320 | 151 | 169 | 47.19% |

## 重点缺口

- `EMChatThreadManager`：16 个 API 全部未覆盖，Thread / 子区能力当前没有 QA 入口。
- `EMConversation`：仅覆盖会话列表展示和整会话已读，缺少本地历史分页、单条已读、本地插入 / 更新 / 删除、会话扩展、置顶消息、本地+服务端删除等 API。
- `EMOptions`：仅覆盖 `withAppKey` 初始化；厂商推送开关、AppId 初始化等配置 API 未覆盖。
- `EMChatManager`：已覆盖发送、已读回执、撤回、修改、远端删除、反应、置顶、会话标记等核心 API；未覆盖合并消息详情、翻译、搜索、本地导入/下载、全量消息统计等。
- `EMClient`：初始化、密码登录、退出、日志压缩、设备查询/踢设备已覆盖；账号创建、token 登录 / 续期、动态设置项、多设备 handler、kickAllDevices 等未覆盖。

## 未覆盖 API 对应功能明细

### 客户端与登录（EMClient）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `addMultiDeviceEventHandler` | 添加多设备事件监听，接收联系人、群组、Thread、会话等多端同步事件 | 登录 / 设置 / 设备管理入口 |
| `changeAppId` | 运行时切换 App ID | 登录 / 设置 / 设备管理入口 |
| `changeAppKey` | 运行时切换 App Key | 登录 / 设置 / 设备管理入口 |
| `clearConnectionEventHandlers` | 清空全部连接事件监听 | 登录 / 设置 / 设备管理入口 |
| `clearMultiDeviceEventHandlers` | 清空全部多设备事件监听 | 登录 / 设置 / 设备管理入口 |
| `createAccount` | 通过 SDK 创建 IM 用户账号 | 登录 / 设置 / 设备管理入口 |
| `getAccessToken` | 获取当前登录用户 access token | 登录 / 设置 / 设备管理入口 |
| `getConnectionEventHandler` | 按 ID 获取连接事件监听 | 登录 / 设置 / 设备管理入口 |
| `getLoggedInDevicesFromServer` | 从服务端获取指定账号已登录设备列表（旧接口） | 登录 / 设置 / 设备管理入口 |
| `getMultiDeviceEventHandler` | 按 ID 获取多设备事件监听 | 登录 / 设置 / 设备管理入口 |
| `isLoginBefore` | 判断本地是否曾经登录过 | 登录 / 设置 / 设备管理入口 |
| `kickAllDevices` | 踢掉账号下所有其他设备 | 登录 / 设置 / 设备管理入口 |
| `login` | 通用登录接口，支持密码或 token 登录模式 | 登录 / 设置 / 设备管理入口 |
| `loginWithAgoraToken` | 使用 Agora token 登录 | 登录 / 设置 / 设备管理入口 |
| `loginWithToken` | 使用用户 token 登录 | 登录 / 设置 / 设备管理入口 |
| `removeMultiDeviceEventHandler` | 移除多设备事件监听 | 登录 / 设置 / 设备管理入口 |
| `renewAgoraToken` | 续期 Agora token | 登录 / 设置 / 设备管理入口 |
| `updateAutoAcceptFriendInvitationSetting` | 更新是否自动接受好友邀请 | 登录 / 设置 / 设备管理入口 |
| `updateAutoAcceptGroupInvitationSetting` | 更新是否自动接受群邀请 | 登录 / 设置 / 设备管理入口 |
| `updateAutoDownloadAttachmentThumbnailSetting` | 更新是否自动下载附件缩略图 | 登录 / 设置 / 设备管理入口 |
| `updateDeleteMessagesWhenLeaveGroupSetting` | 更新退群时是否删除群消息配置 | 登录 / 设置 / 设备管理入口 |
| `updateDeleteMessageWhenLeaveRoomSetting` | 更新退出聊天室时是否删除聊天室消息配置 | 登录 / 设置 / 设备管理入口 |
| `updateDeliveryAckSetting` | 更新是否需要发送送达回执配置 | 登录 / 设置 / 设备管理入口 |
| `updateLoginExtensionInfoSetting` | 更新登录扩展信息配置 | 登录 / 设置 / 设备管理入口 |
| `updateMessagesReceiveCallbackIncludeSendSetting` | 更新消息接收回调是否包含自己发送的消息 | 登录 / 设置 / 设备管理入口 |
| `updateRegradeMessagesAsReadSetting` | 更新收到消息是否标记为已读配置 | 登录 / 设置 / 设备管理入口 |
| `updateRequireAckSetting` | 更新是否需要已读回执配置 | 登录 / 设置 / 设备管理入口 |
| `updateRoomOwnerCanLeaveSetting` | 更新聊天室所有者是否可退出聊天室配置 | 登录 / 设置 / 设备管理入口 |
| `updateSortMessageByServerTimeSetting` | 更新消息是否按服务端时间排序配置 | 登录 / 设置 / 设备管理入口 |
| `updateUsingHttpsOnlySetting` | 更新是否仅使用 HTTPS 配置 | 登录 / 设置 / 设备管理入口 |

### 消息管理（EMChatManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `clearAllMessageEvents` | 清空全部消息发送状态监听 | 聊天页消息工具或会话列表工具入口 |
| `clearEventHandlers` | 清空全部聊天事件监听 | 聊天页消息工具或会话列表工具入口 |
| `clearMessageEvent` | 清空消息发送状态监听集合 | 聊天页消息工具或会话列表工具入口 |
| `deleteAllMessageAndConversation` | 删除本地全部消息和会话 | 聊天页消息工具或会话列表工具入口 |
| `deleteConversation` | 删除本地会话，可选择是否删除本地消息 | 聊天页消息工具或会话列表工具入口 |
| `deleteMessagesBefore` | 按时间删除本地历史消息 | 聊天页消息工具或会话列表工具入口 |
| `downloadAttachment` | 下载消息附件原文件 | 聊天页消息工具或会话列表工具入口 |
| `downloadMessageAttachmentInCombine` | 下载合并消息内附件原文件 | 聊天页消息工具或会话列表工具入口 |
| `downloadMessageThumbnailInCombine` | 下载合并消息内附件缩略图 | 聊天页消息工具或会话列表工具入口 |
| `downloadThumbnail` | 下载消息附件缩略图 | 聊天页消息工具或会话列表工具入口 |
| `fetchCombineMessageDetail` | 获取合并消息详情 | 聊天页消息工具或会话列表工具入口 |
| `fetchConversation` | 分页从服务端获取会话列表 | 聊天页消息工具或会话列表工具入口 |
| `fetchConversationListFromServer` | 从服务端获取会话列表 | 聊天页消息工具或会话列表工具入口 |
| `fetchHistoryMessages` | 分页拉取服务端历史消息 | 聊天页消息工具或会话列表工具入口 |
| `fetchPinnedConversations` | 分页获取置顶会话 | 聊天页消息工具或会话列表工具入口 |
| `fetchReactionDetail` | 分页获取指定 reaction 的用户详情 | 聊天页消息工具或会话列表工具入口 |
| `fetchReactionList` | 批量获取消息 reaction 概览 | 聊天页消息工具或会话列表工具入口 |
| `fetchSupportedLanguages` | 获取消息翻译支持的语言列表 | 聊天页消息工具或会话列表工具入口 |
| `getAllMessageCount` | 获取本地全部消息数量 | 聊天页消息工具或会话列表工具入口 |
| `getConversation` | 获取或创建本地会话 | 聊天页消息工具或会话列表工具入口 |
| `getConversationsFromServer` | 从服务端获取会话列表（旧接口） | 聊天页消息工具或会话列表工具入口 |
| `getEventHandler` | 按 ID 获取聊天事件监听 | 聊天页消息工具或会话列表工具入口 |
| `getThreadConversation` | 获取 Thread 会话 | 聊天页消息工具或会话列表工具入口 |
| `getUnreadMessageCount` | 获取本地全部未读消息数 | 聊天页消息工具或会话列表工具入口 |
| `importMessages` | 导入本地消息 | 聊天页消息工具或会话列表工具入口 |
| `loadConversationMessagesWithKeyword` | 按关键字跨会话搜索本地消息 | 聊天页消息工具或会话列表工具入口 |
| `loadMessagesWithIds` | 按消息 ID 批量加载本地消息 | 聊天页消息工具或会话列表工具入口 |
| `loadMessagesWithKeyword` | 按关键字加载本地消息 | 聊天页消息工具或会话列表工具入口 |
| `markAllConversationsAsRead` | 将全部会话标记为已读 | 聊天页消息工具或会话列表工具入口 |
| `removeMessageEvent` | 移除消息发送状态监听 | 聊天页消息工具或会话列表工具入口 |
| `reportMessage` | 举报消息 | 聊天页消息工具或会话列表工具入口 |
| `resendMessage` | 重发消息 | 聊天页消息工具或会话列表工具入口 |
| `searchMsgFromDB` | 按条件搜索本地消息 | 聊天页消息工具或会话列表工具入口 |
| `searchMsgsByOptions` | 按高级条件搜索消息 | 聊天页消息工具或会话列表工具入口 |
| `sendConversationReadAck` | 发送会话已读回执 | 聊天页消息工具或会话列表工具入口 |
| `translateMessage` | 翻译消息 | 聊天页消息工具或会话列表工具入口 |
| `updateMessage` | 更新本地消息 | 聊天页消息工具或会话列表工具入口 |

### 群组管理（EMGroupManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `changeGroupDescription` | 修改群描述（旧接口） | 群组页 / 群成员页补充入口 |
| `changeGroupName` | 修改群名称（旧接口） | 群组页 / 群成员页补充入口 |
| `clearAllGroupsFromLocal` | 清空本地群组缓存 | 群组页 / 群成员页补充入口 |
| `clearEventHandlers` | 清空全部群组事件监听 | 群组页 / 群成员页补充入口 |
| `downloadGroupSharedFile` | 下载群共享文件 | 群组页 / 群成员页补充入口 |
| `fetchAnnouncementFromServer` | 从服务端获取群公告 | 群组页 / 群成员页补充入口 |
| `fetchGroupFileListFromServer` | 从服务端获取群共享文件列表 | 群组页 / 群成员页补充入口 |
| `fetchGroupMembersInfo` | 获取群成员资料 / 名片信息 | 群组页 / 群成员页补充入口 |
| `fetchMembersAttributes` | 批量获取多个群成员自定义属性 | 群组页 / 群成员页补充入口 |
| `fetchPublicGroupsFromServer` | 分页获取公开群列表 | 群组页 / 群成员页补充入口 |
| `getEventHandler` | 按 ID 获取群组事件监听 | 群组页 / 群成员页补充入口 |
| `getGroupWithId` | 从本地获取指定群组 | 群组页 / 群成员页补充入口 |
| `getJoinedGroups` | 从本地获取已加入群组列表 | 群组页 / 群成员页补充入口 |
| `inviterUser` | 邀请用户入群（旧接口命名） | 群组页 / 群成员页补充入口 |
| `isMemberInAllowListFromServer` | 查询当前用户是否在群白名单 | 群组页 / 群成员页补充入口 |
| `isMemberInGroupMuteList` | 查询成员是否在群禁言列表 | 群组页 / 群成员页补充入口 |
| `removeGroupSharedFile` | 删除群共享文件 | 群组页 / 群成员页补充入口 |
| `removeMemberAttributes` | 删除群成员自定义属性 | 群组页 / 群成员页补充入口 |
| `updateGroupAvatar` | 更新群头像 | 群组页 / 群成员页补充入口 |
| `updateGroupExtension` | 更新群扩展字段 | 群组页 / 群成员页补充入口 |
| `uploadGroupSharedFile` | 上传群共享文件 | 群组页 / 群成员页补充入口 |

### 聊天室管理（EMChatRoomManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `clearEventHandlers` | 清空全部聊天室事件监听 | 聊天室页 / 成员页补充入口 |
| `fetchChatRoomAnnouncement` | 获取聊天室公告 | 聊天室页 / 成员页补充入口 |
| `getChatRoomWithId` | 从本地获取指定聊天室 | 聊天室页 / 成员页补充入口 |
| `getEventHandler` | 按 ID 获取聊天室事件监听 | 聊天室页 / 成员页补充入口 |
| `isMemberInChatRoomAllowList` | 查询当前用户是否在聊天室白名单 | 聊天室页 / 成员页补充入口 |
| `isMemberInChatRoomMuteList` | 查询当前用户是否在聊天室禁言列表 | 聊天室页 / 成员页补充入口 |
| `removeEventHandler` | 移除聊天室事件监听 | 聊天室页 / 成员页补充入口 |

### 联系人管理（EMContactManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `clearEventHandlers` | 清空全部联系人事件监听 | 联系人页补充入口 |
| `fetchAllContactIds` | 从服务端获取联系人 ID 列表 | 联系人页补充入口 |
| `fetchContacts` | 分页获取联系人 | 联系人页补充入口 |
| `getAllContactIds` | 从本地获取联系人 ID 列表 | 联系人页补充入口 |
| `getAllContacts` | 获取联系人列表（兼容接口） | 联系人页补充入口 |
| `getAllContactsFromDB` | 从本地数据库获取联系人列表 | 联系人页补充入口 |
| `getAllContactsFromServer` | 从服务端获取联系人列表（旧接口） | 联系人页补充入口 |
| `getBlockIds` | 从本地获取黑名单 ID 列表 | 联系人页补充入口 |
| `getBlockListFromDB` | 从本地数据库获取黑名单 | 联系人页补充入口 |
| `getBlockListFromServer` | 从服务端获取黑名单 | 联系人页补充入口 |
| `getContact` | 获取单个联系人详情 | 联系人页补充入口 |
| `getEventHandler` | 按 ID 获取联系人事件监听 | 联系人页补充入口 |

### Presence（EMPresenceManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `clearEventHandlers` | 清空全部 Presence 事件监听 | 补充 QA 入口 |
| `getEventHandler` | 按 ID 获取 Presence 事件监听 | 补充 QA 入口 |

### 离线推送（EMPushManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `fetchPreferredNotificationLanguage` | 获取推送翻译语言 | 推送设置页补充入口 |
| `fetchSilentModeForConversations` | 批量获取多个会话的静默设置 | 推送设置页补充入口 |
| `setPreferredNotificationLanguage` | 设置推送翻译语言 | 推送设置页补充入口 |
| `updateAPNsDeviceToken` | 更新 APNs 设备 token（旧接口） | 推送设置页补充入口 |
| `updateFCMPushToken` | 更新 FCM 设备 token（旧接口） | 推送设置页补充入口 |
| `updateHMSPushToken` | 更新华为 HMS 设备 token（旧接口） | 推送设置页补充入口 |

### 用户属性（EMUserInfoManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `clearUserInfoCache` | 清空用户属性缓存 | 补充 QA 入口 |

### Thread / 子区（EMChatThreadManager）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `addEventHandler` | 添加 Thread 事件监听 | 新增 Thread / 子区 QA 页或入口 |
| `clearEventHandlers` | 清空全部 Thread 事件监听 | 新增 Thread / 子区 QA 页或入口 |
| `createChatThread` | 创建 Thread / 子区 | 新增 Thread / 子区 QA 页或入口 |
| `destroyChatThread` | 解散 Thread / 子区 | 新增 Thread / 子区 QA 页或入口 |
| `fetchChatThread` | 获取 Thread / 子区详情 | 新增 Thread / 子区 QA 页或入口 |
| `fetchChatThreadMembers` | 分页获取 Thread 成员列表 | 新增 Thread / 子区 QA 页或入口 |
| `fetchChatThreadsWithParentId` | 获取指定父消息下的 Thread 列表 | 新增 Thread / 子区 QA 页或入口 |
| `fetchJoinedChatThreads` | 获取当前用户加入的 Thread 列表 | 新增 Thread / 子区 QA 页或入口 |
| `fetchJoinedChatThreadsWithParentId` | 获取当前用户在指定父消息下加入的 Thread 列表 | 新增 Thread / 子区 QA 页或入口 |
| `fetchLatestMessageWithChatThreads` | 批量获取 Thread 最新消息 | 新增 Thread / 子区 QA 页或入口 |
| `getEventHandler` | 按 ID 获取 Thread 事件监听 | 新增 Thread / 子区 QA 页或入口 |
| `joinChatThread` | 加入 Thread / 子区 | 新增 Thread / 子区 QA 页或入口 |
| `leaveChatThread` | 退出 Thread / 子区 | 新增 Thread / 子区 QA 页或入口 |
| `removeEventHandler` | 移除 Thread 事件监听 | 新增 Thread / 子区 QA 页或入口 |
| `removeMemberFromChatThread` | 从 Thread 移除成员 | 新增 Thread / 子区 QA 页或入口 |
| `updateChatThreadName` | 修改 Thread 名称 | 新增 Thread / 子区 QA 页或入口 |

### 消息对象工厂 / 实例方法（EMMessage）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `chatroomMessagePriority` | 设置聊天室消息优先级 | 消息类型 / 消息详情工具入口 |
| `chatThread` | 获取消息所属 Thread 信息 | 消息类型 / 消息详情工具入口 |
| `createCombineSendMessage` | 创建合并转发消息 | 消息类型 / 消息详情工具入口 |
| `createReceiveMessage` | 创建接收方向消息对象 | 消息类型 / 消息详情工具入口 |
| `createSendMessage` | 创建基础发送消息对象 | 消息类型 / 消息详情工具入口 |
| `groupAckCount` | 获取群消息已读回执数量 | 消息类型 / 消息详情工具入口 |
| `reactionList` | 获取消息 reaction 列表 | 消息类型 / 消息详情工具入口 |

### 会话对象方法（EMConversation）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `appendMessage` | 向会话尾部追加本地消息 | 会话详情 / 本地消息 QA 面板 |
| `deleteAllMessages` | 删除会话内全部本地消息 | 会话详情 / 本地消息 QA 面板 |
| `deleteLocalAndServerMessages` | 按消息 ID 删除本地和服务端消息 | 会话详情 / 本地消息 QA 面板 |
| `deleteLocalAndServerMessagesByTime` | 按时间删除本地和服务端消息 | 会话详情 / 本地消息 QA 面板 |
| `deleteMessage` | 删除单条本地消息 | 会话详情 / 本地消息 QA 面板 |
| `deleteMessageByIds` | 按 ID 批量删除本地消息 | 会话详情 / 本地消息 QA 面板 |
| `deleteMessagesWithTs` | 按时间段删除本地消息 | 会话详情 / 本地消息 QA 面板 |
| `getLocalMessageCount` | 按条件获取本地消息数量 | 会话详情 / 本地消息 QA 面板 |
| `insertMessage` | 向会话插入本地消息 | 会话详情 / 本地消息 QA 面板 |
| `lastReceivedMessage` | 获取对方发来的最后一条消息 | 会话详情 / 本地消息 QA 面板 |
| `loadMessages` | 分页加载本地历史消息 | 会话详情 / 本地消息 QA 面板 |
| `loadMessagesFromTime` | 按时间范围加载本地消息 | 会话详情 / 本地消息 QA 面板 |
| `loadMessagesWithKeyword` | 按关键字加载会话本地消息 | 会话详情 / 本地消息 QA 面板 |
| `loadMessagesWithMsgType` | 按消息类型加载本地消息 | 会话详情 / 本地消息 QA 面板 |
| `loadPinnedMessages` | 加载会话内置顶消息 | 会话详情 / 本地消息 QA 面板 |
| `markMessageAsRead` | 将指定消息标记为已读 | 会话详情 / 本地消息 QA 面板 |
| `messagesCount` | 获取会话内消息总数 | 会话详情 / 本地消息 QA 面板 |
| `remindType` | 获取会话推送提醒类型 | 会话详情 / 本地消息 QA 面板 |
| `searchMsgsByOptions` | 按高级选项搜索会话消息 | 会话详情 / 本地消息 QA 面板 |
| `setExt` | 设置会话扩展字段 | 会话详情 / 本地消息 QA 面板 |
| `updateMessage` | 更新会话内本地消息 | 会话详情 / 本地消息 QA 面板 |

### 初始化配置（EMOptions）

| API | 对应功能 | 建议入口 |
| --- | --- | --- |
| `enableAPNs` | 启用 APNs 推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableFCM` | 启用 FCM 推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableHonorPush` | 启用荣耀推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableHWPush` | 启用华为推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableMeiZuPush` | 启用魅族推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableMiPush` | 启用小米推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableOppoPush` | 启用 OPPO 推送配置 | 服务器设置 / 推送厂商配置入口 |
| `enableVivoPush` | 启用 vivo 推送配置 | 服务器设置 / 推送厂商配置入口 |
| `withAppId` | 使用 App ID 构造 SDK 初始化配置 | 登录初始化配置入口 |

## 全量 API 覆盖明细

### 客户端与登录（EMClient）

覆盖：12/42（28.57%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `addConnectionEventHandler` | 已覆盖 | lib/common/utils/chat_event_widget.dart:28<br>lib/pages/home_page.dart:198 |
| `addMultiDeviceEventHandler` | 未覆盖 | - |
| `changeAppId` | 未覆盖 | - |
| `changeAppKey` | 未覆盖 | - |
| `clearConnectionEventHandlers` | 未覆盖 | - |
| `clearMultiDeviceEventHandlers` | 未覆盖 | - |
| `compressLogs` | 已覆盖 | lib/common/utils/log_file_helper.dart:40 |
| `createAccount` | 未覆盖 | - |
| `fetchLoggedInDevices` | 已覆盖 | lib/pages/single/contact_api.dart:11 |
| `getAccessToken` | 未覆盖 | - |
| `getConnectionEventHandler` | 未覆盖 | - |
| `getCurrentDeviceId` | 已覆盖 | lib/common/widgets/common_dialogs.dart:12<br>lib/common/widgets/info_dialog.dart:43 |
| `getCurrentUserId` | 已覆盖 | lib/common/widgets/common_dialogs.dart:11<br>lib/common/widgets/info_dialog.dart:42<br>lib/pages/chatroom/room_members_page.dart:132 |
| `getLoggedInDevicesFromServer` | 未覆盖 | - |
| `getMultiDeviceEventHandler` | 未覆盖 | - |
| `init` | 已覆盖 | lib/common/mixins/login_logic_mixin.dart:11 |
| `isConnected` | 已覆盖 | lib/pages/home_page.dart:194 |
| `isLoginBefore` | 未覆盖 | - |
| `kickAllDevices` | 未覆盖 | - |
| `kickDevice` | 已覆盖 | lib/pages/single/contact_api.dart:27 |
| `login` | 未覆盖 | - |
| `loginWithAgoraToken` | 未覆盖 | - |
| `loginWithPassword` | 已覆盖 | lib/common/mixins/login_logic_mixin.dart:136 |
| `loginWithToken` | 未覆盖 | - |
| `logout` | 已覆盖 | lib/common/mixins/login_logic_mixin.dart:134<br>lib/common/session_scope.dart:57 |
| `removeConnectionEventHandler` | 已覆盖 | lib/common/utils/chat_event_widget.dart:23<br>lib/pages/home_page.dart:57 |
| `removeMultiDeviceEventHandler` | 未覆盖 | - |
| `renewAgoraToken` | 未覆盖 | - |
| `startCallback` | 已覆盖 | lib/common/utils/chat_event_widget.dart:56<br>lib/pages/home_page.dart:50 |
| `updateAutoAcceptFriendInvitationSetting` | 未覆盖 | - |
| `updateAutoAcceptGroupInvitationSetting` | 未覆盖 | - |
| `updateAutoDownloadAttachmentThumbnailSetting` | 未覆盖 | - |
| `updateDeleteMessagesWhenLeaveGroupSetting` | 未覆盖 | - |
| `updateDeleteMessageWhenLeaveRoomSetting` | 未覆盖 | - |
| `updateDeliveryAckSetting` | 未覆盖 | - |
| `updateLoginExtensionInfoSetting` | 未覆盖 | - |
| `updateMessagesReceiveCallbackIncludeSendSetting` | 未覆盖 | - |
| `updateRegradeMessagesAsReadSetting` | 未覆盖 | - |
| `updateRequireAckSetting` | 未覆盖 | - |
| `updateRoomOwnerCanLeaveSetting` | 未覆盖 | - |
| `updateSortMessageByServerTimeSetting` | 未覆盖 | - |
| `updateUsingHttpsOnlySetting` | 未覆盖 | - |

### 消息管理（EMChatManager）

覆盖：24/61（39.34%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `addEventHandler` | 已覆盖 | lib/pages/chatroom/room_page.dart:243<br>lib/pages/conversation/conversation_list_page.dart:60<br>lib/pages/group/group_page.dart:177 |
| `addMessageEvent` | 已覆盖 | lib/pages/chatroom/room_page.dart:231<br>lib/pages/group/group_page.dart:165<br>lib/pages/single/single_chat_page.dart:76 |
| `addReaction` | 已覆盖 | lib/pages/single/single_chat_page.dart:342 |
| `addRemoteAndLocalConversationsMark` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:298 |
| `clearAllMessageEvents` | 未覆盖 | - |
| `clearEventHandlers` | 未覆盖 | - |
| `clearMessageEvent` | 未覆盖 | - |
| `deleteAllMessageAndConversation` | 未覆盖 | - |
| `deleteConversation` | 未覆盖 | - |
| `deleteMessagesBefore` | 未覆盖 | - |
| `deleteRemoteAndLocalConversationsMark` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:323 |
| `deleteRemoteConversation` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:405 |
| `deleteRemoteMessagesBefore` | 已覆盖 | lib/pages/chatroom/room_page.dart:687 |
| `deleteRemoteMessagesWithIds` | 已覆盖 | lib/pages/chatroom/room_page.dart:670<br>lib/pages/single/single_chat_page.dart:413 |
| `downloadAttachment` | 未覆盖 | - |
| `downloadMessageAttachmentInCombine` | 未覆盖 | - |
| `downloadMessageThumbnailInCombine` | 未覆盖 | - |
| `downloadThumbnail` | 未覆盖 | - |
| `fetchCombineMessageDetail` | 未覆盖 | - |
| `fetchConversation` | 未覆盖 | - |
| `fetchConversationListFromServer` | 未覆盖 | - |
| `fetchConversationsByOptions` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:185 |
| `fetchGroupAcks` | 已覆盖 | lib/pages/group/group_page.dart:614 |
| `fetchHistoryMessages` | 未覆盖 | - |
| `fetchHistoryMessagesByOption` | 已覆盖 | lib/pages/single/single_chat_page.dart:706 |
| `fetchPinnedConversations` | 未覆盖 | - |
| `fetchPinnedMessages` | 已覆盖 | lib/pages/single/single_chat_page.dart:759 |
| `fetchReactionDetail` | 未覆盖 | - |
| `fetchReactionList` | 未覆盖 | - |
| `fetchSupportedLanguages` | 未覆盖 | - |
| `getAllMessageCount` | 未覆盖 | - |
| `getConversation` | 未覆盖 | - |
| `getConversationsFromServer` | 未覆盖 | - |
| `getEventHandler` | 未覆盖 | - |
| `getThreadConversation` | 未覆盖 | - |
| `getUnreadMessageCount` | 未覆盖 | - |
| `importMessages` | 未覆盖 | - |
| `loadAllConversations` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:211 |
| `loadConversationMessagesWithKeyword` | 未覆盖 | - |
| `loadMessage` | 已覆盖 | lib/pages/single/single_chat_page.dart:305 |
| `loadMessagesWithIds` | 未覆盖 | - |
| `loadMessagesWithKeyword` | 未覆盖 | - |
| `markAllConversationsAsRead` | 未覆盖 | - |
| `modifyMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:653<br>lib/pages/single/single_chat_page.dart:438 |
| `pinConversation` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:369 |
| `pinMessage` | 已覆盖 | lib/pages/single/single_chat_page.dart:368 |
| `recallMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:98<br>lib/pages/single/single_chat_page.dart:467 |
| `removeEventHandler` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:77<br>lib/pages/home_page.dart:60 |
| `removeMessageEvent` | 未覆盖 | - |
| `removeReaction` | 已覆盖 | lib/pages/single/single_chat_page.dart:348 |
| `reportMessage` | 未覆盖 | - |
| `resendMessage` | 未覆盖 | - |
| `searchMsgFromDB` | 未覆盖 | - |
| `searchMsgsByOptions` | 未覆盖 | - |
| `sendConversationReadAck` | 未覆盖 | - |
| `sendGroupMessageReadAck` | 已覆盖 | lib/pages/group/group_page.dart:596 |
| `sendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:740<br>lib/pages/group/group_page.dart:548<br>lib/pages/single/single_chat_page.dart:502 |
| `sendMessageReadAck` | 已覆盖 | lib/pages/single/single_chat_page.dart:316 |
| `translateMessage` | 未覆盖 | - |
| `unpinMessage` | 已覆盖 | lib/pages/single/single_chat_page.dart:390 |
| `updateMessage` | 未覆盖 | - |

### 群组管理（EMGroupManager）

覆盖：38/59（64.41%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `acceptInvitation` | 已覆盖 | lib/pages/group/group_list_page.dart:120 |
| `acceptJoinApplication` | 已覆盖 | lib/pages/group/group_list_page.dart:164 |
| `addAdmin` | 已覆盖 | lib/pages/group/group_members_page.dart:355 |
| `addAllowList` | 已覆盖 | lib/pages/group/group_members_page.dart:388 |
| `addEventHandler` | 已覆盖 | lib/pages/group/group_list_page.dart:39<br>lib/pages/group/group_page.dart:177<br>lib/pages/home_page.dart:79 |
| `addMembers` | 已覆盖 | lib/pages/group/group_members_page.dart:140 |
| `blockGroup` | 已覆盖 | lib/pages/group/group_page.dart:344 |
| `blockMembers` | 已覆盖 | lib/pages/group/group_members_page.dart:422 |
| `changeGroupDescription` | 未覆盖 | - |
| `changeGroupName` | 未覆盖 | - |
| `changeOwner` | 已覆盖 | lib/pages/group/group_change_owner_page.dart:225 |
| `clearAllGroupsFromLocal` | 未覆盖 | - |
| `clearEventHandlers` | 未覆盖 | - |
| `createGroup` | 已覆盖 | lib/pages/group/group_page.dart:322 |
| `declineInvitation` | 已覆盖 | lib/pages/group/group_list_page.dart:142 |
| `declineJoinApplication` | 已覆盖 | lib/pages/group/group_list_page.dart:188 |
| `destroyGroup` | 已覆盖 | lib/pages/group/group_page.dart:336 |
| `downloadGroupSharedFile` | 未覆盖 | - |
| `fetchAllowListFromServer` | 已覆盖 | lib/pages/group/group_white_list_page.dart:45 |
| `fetchAnnouncementFromServer` | 未覆盖 | - |
| `fetchBlockListFromServer` | 已覆盖 | lib/pages/group/group_members_page.dart:810 |
| `fetchGroupFileListFromServer` | 未覆盖 | - |
| `fetchGroupInfoFromServer` | 已覆盖 | lib/pages/group/group_admins_page.dart:78<br>lib/pages/group/group_change_owner_page.dart:144<br>lib/pages/group/group_page.dart:283 |
| `fetchGroupMembersInfo` | 未覆盖 | - |
| `fetchJoinedGroupCount` | 已覆盖 | lib/pages/group/group_list_page.dart:304 |
| `fetchJoinedGroupsFromServer` | 已覆盖 | lib/pages/group/group_list_page.dart:231 |
| `fetchMemberAttributes` | 已覆盖 | lib/pages/group/group_members_page.dart:440 |
| `fetchMemberListFromServer` | 已覆盖 | lib/pages/group/group_change_owner_page.dart:156<br>lib/pages/group/group_members_page.dart:345 |
| `fetchMembersAttributes` | 未覆盖 | - |
| `fetchMuteListFromServer` | 已覆盖 | lib/pages/group/group_mute_list_page.dart:62 |
| `fetchPublicGroupsFromServer` | 未覆盖 | - |
| `getEventHandler` | 未覆盖 | - |
| `getGroupWithId` | 未覆盖 | - |
| `getJoinedGroups` | 未覆盖 | - |
| `inviterUser` | 未覆盖 | - |
| `isMemberInAllowListFromServer` | 未覆盖 | - |
| `isMemberInGroupMuteList` | 未覆盖 | - |
| `joinPublicGroup` | 已覆盖 | lib/pages/group/group_page.dart:291 |
| `leaveGroup` | 已覆盖 | lib/pages/group/group_page.dart:501 |
| `muteAllMembers` | 已覆盖 | lib/pages/group/group_page.dart:782 |
| `muteMembers` | 已覆盖 | lib/pages/group/group_members_page.dart:372 |
| `removeAdmin` | 已覆盖 | lib/pages/group/group_admins_page.dart:144 |
| `removeAllowList` | 已覆盖 | lib/pages/group/group_white_list_page.dart:114 |
| `removeEventHandler` | 已覆盖 | lib/pages/group/group_list_page.dart:108<br>lib/pages/home_page.dart:60 |
| `removeGroupSharedFile` | 未覆盖 | - |
| `removeMemberAttributes` | 未覆盖 | - |
| `removeMembers` | 已覆盖 | lib/pages/group/group_members_page.dart:405 |
| `requestToJoinPublicGroup` | 已覆盖 | lib/pages/group/group_page.dart:299 |
| `setMemberAttributes` | 已覆盖 | lib/pages/group/group_page.dart:1091 |
| `unblockGroup` | 已覆盖 | lib/pages/group/group_page.dart:352 |
| `unblockMembers` | 已覆盖 | lib/pages/group/group_members_page.dart:871 |
| `unMuteAllMembers` | 已覆盖 | lib/pages/group/group_page.dart:784 |
| `unMuteMembers` | 已覆盖 | lib/pages/group/group_mute_list_page.dart:173 |
| `updateGroupAnnouncement` | 已覆盖 | lib/pages/group/group_page.dart:693 |
| `updateGroupAvatar` | 未覆盖 | - |
| `updateGroupDesc` | 已覆盖 | lib/pages/group/group_page.dart:687 |
| `updateGroupExtension` | 未覆盖 | - |
| `updateGroupName` | 已覆盖 | lib/pages/group/group_page.dart:681 |
| `uploadGroupSharedFile` | 未覆盖 | - |

### 聊天室管理（EMChatRoomManager）

覆盖：29/36（80.56%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `addAttributes` | 已覆盖 | lib/pages/chatroom/room_page.dart:1261 |
| `addChatRoomAdmin` | 已覆盖 | lib/pages/chatroom/room_members_page.dart:273 |
| `addEventHandler` | 已覆盖 | lib/pages/chatroom/room_page.dart:243 |
| `addMembersToChatRoomAllowList` | 已覆盖 | lib/pages/chatroom/room_members_page.dart:305 |
| `blockChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_members_page.dart:325 |
| `changeChatRoomDescription` | 已覆盖 | lib/pages/chatroom/room_page.dart:870 |
| `changeChatRoomName` | 已覆盖 | lib/pages/chatroom/room_page.dart:863 |
| `changeOwner` | 已覆盖 | lib/pages/chatroom/room_change_owner_page.dart:159 |
| `clearEventHandlers` | 未覆盖 | - |
| `createChatRoom` | 已覆盖 | lib/pages/chatroom/room_page.dart:212 |
| `destroyChatRoom` | 已覆盖 | lib/pages/chatroom/room_page.dart:1035 |
| `fetchChatRoomAllowListFromServer` | 已覆盖 | lib/pages/chatroom/room_white_list_page.dart:44 |
| `fetchChatRoomAnnouncement` | 未覆盖 | - |
| `fetchChatRoomAttributes` | 已覆盖 | lib/pages/chatroom/room_page.dart:1074 |
| `fetchChatRoomBlockList` | 已覆盖 | lib/pages/chatroom/room_block_list_page.dart:69 |
| `fetchChatRoomInfoFromServer` | 已覆盖 | lib/common/widgets/info_dialog.dart:48<br>lib/pages/chatroom/room_admins_page.dart:43<br>lib/pages/chatroom/room_change_owner_page.dart:135 |
| `fetchChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_change_owner_page.dart:147<br>lib/pages/chatroom/room_members_page.dart:264<br>lib/pages/chatroom/room_page.dart:786 |
| `fetchChatRoomMuteList` | 已覆盖 | lib/pages/chatroom/room_mute_list_page.dart:59 |
| `fetchPublicChatRoomsFromServer` | 已覆盖 | lib/pages/chatroom/room_list_page.dart:59 |
| `getChatRoomWithId` | 未覆盖 | - |
| `getEventHandler` | 未覆盖 | - |
| `isMemberInChatRoomAllowList` | 未覆盖 | - |
| `isMemberInChatRoomMuteList` | 未覆盖 | - |
| `joinChatRoom` | 已覆盖 | lib/pages/chatroom/room_page.dart:714 |
| `leaveChatRoom` | 已覆盖 | lib/pages/chatroom/room_page.dart:701 |
| `muteAllChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_page.dart:946 |
| `muteChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_members_page.dart:289 |
| `removeAttributes` | 已覆盖 | lib/pages/chatroom/room_page.dart:1053 |
| `removeChatRoomAdmin` | 已覆盖 | lib/pages/chatroom/room_admins_page.dart:110 |
| `removeChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_members_page.dart:346 |
| `removeEventHandler` | 未覆盖 | - |
| `removeMembersFromChatRoomAllowList` | 已覆盖 | lib/pages/chatroom/room_white_list_page.dart:111 |
| `unBlockChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_block_list_page.dart:183 |
| `unMuteAllChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_page.dart:950 |
| `unMuteChatRoomMembers` | 已覆盖 | lib/pages/chatroom/room_mute_list_page.dart:165 |
| `updateChatRoomAnnouncement` | 已覆盖 | lib/pages/chatroom/room_page.dart:874 |

### 联系人管理（EMContactManager）

覆盖：12/24（50.00%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `acceptInvitation` | 已覆盖 | lib/pages/single/single_chat_list_page.dart:91 |
| `addContact` | 已覆盖 | lib/pages/single/single_chat_list_page.dart:233 |
| `addEventHandler` | 已覆盖 | lib/pages/home_page.dart:79<br>lib/pages/single/single_chat_list_page.dart:38 |
| `addUserToBlockList` | 已覆盖 | lib/pages/single/contact_api.dart:36 |
| `clearEventHandlers` | 未覆盖 | - |
| `declineInvitation` | 已覆盖 | lib/pages/single/single_chat_list_page.dart:114 |
| `deleteContact` | 已覆盖 | lib/pages/single/single_chat_list_page.dart:251 |
| `fetchAllContactIds` | 未覆盖 | - |
| `fetchAllContacts` | 已覆盖 | lib/pages/single/contact_api.dart:4 |
| `fetchBlockIds` | 已覆盖 | lib/pages/single/black_list_page.dart:48 |
| `fetchContacts` | 未覆盖 | - |
| `getAllContactIds` | 未覆盖 | - |
| `getAllContacts` | 未覆盖 | - |
| `getAllContactsFromDB` | 未覆盖 | - |
| `getAllContactsFromServer` | 未覆盖 | - |
| `getBlockIds` | 未覆盖 | - |
| `getBlockListFromDB` | 未覆盖 | - |
| `getBlockListFromServer` | 未覆盖 | - |
| `getContact` | 未覆盖 | - |
| `getEventHandler` | 未覆盖 | - |
| `getSelfIdsOnOtherPlatform` | 已覆盖 | lib/pages/single/contact_api.dart:8 |
| `removeEventHandler` | 已覆盖 | lib/pages/home_page.dart:60 |
| `removeUserFromBlockList` | 已覆盖 | lib/pages/single/black_list_page.dart:52 |
| `setContactRemark` | 已覆盖 | lib/pages/single/contact_api.dart:43 |

### Presence（EMPresenceManager）

覆盖：7/9（77.78%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `addEventHandler` | 已覆盖 | lib/pages/single/contact_presence_page.dart:98 |
| `clearEventHandlers` | 未覆盖 | - |
| `fetchPresenceStatus` | 已覆盖 | lib/pages/single/contact_api.dart:65 |
| `fetchSubscribedMembers` | 已覆盖 | lib/pages/single/contact_api.dart:50 |
| `getEventHandler` | 未覆盖 | - |
| `publishPresence` | 已覆盖 | lib/pages/single/contact_api.dart:79 |
| `removeEventHandler` | 已覆盖 | lib/pages/single/contact_presence_page.dart:82 |
| `subscribe` | 已覆盖 | lib/pages/single/contact_api.dart:54 |
| `unsubscribe` | 已覆盖 | lib/pages/single/contact_api.dart:61 |

### 离线推送（EMPushManager）

覆盖：12/18（66.67%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `bindDeviceToken` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:42 |
| `fetchConversationSilentMode` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:47 |
| `fetchPreferredNotificationLanguage` | 未覆盖 | - |
| `fetchPushConfigsFromServer` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:316 |
| `fetchSilentModeForAll` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:44 |
| `fetchSilentModeForConversations` | 未覆盖 | - |
| `getPushTemplate` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:52 |
| `removeConversationSilentMode` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:46 |
| `setConversationSilentMode` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:45 |
| `setPreferredNotificationLanguage` | 未覆盖 | - |
| `setPushTemplate` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:51 |
| `setSilentModeForAll` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:43 |
| `syncConversationsSilentMode` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:48 |
| `updateAPNsDeviceToken` | 未覆盖 | - |
| `updateFCMPushToken` | 未覆盖 | - |
| `updateHMSPushToken` | 未覆盖 | - |
| `updatePushDisplayStyle` | 已覆盖 | lib/mobile/push_settings_page_mobile.dart:49 |
| `updatePushNickname` | 已覆盖 | lib/mobile/my_page_mobile.dart:17 |

### 用户属性（EMUserInfoManager）

覆盖：3/4（75.00%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `clearUserInfoCache` | 未覆盖 | - |
| `fetchOwnInfo` | 已覆盖 | lib/mobile/my_user_profile_page_mobile.dart:22 |
| `fetchUserInfoById` | 已覆盖 | lib/mobile/user_info_lookup_page_mobile.dart:75 |
| `updateUserInfo` | 已覆盖 | lib/mobile/my_user_profile_page_mobile.dart:109 |

### Thread / 子区（EMChatThreadManager）

覆盖：0/16（0.00%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `addEventHandler` | 未覆盖 | - |
| `clearEventHandlers` | 未覆盖 | - |
| `createChatThread` | 未覆盖 | - |
| `destroyChatThread` | 未覆盖 | - |
| `fetchChatThread` | 未覆盖 | - |
| `fetchChatThreadMembers` | 未覆盖 | - |
| `fetchChatThreadsWithParentId` | 未覆盖 | - |
| `fetchJoinedChatThreads` | 未覆盖 | - |
| `fetchJoinedChatThreadsWithParentId` | 未覆盖 | - |
| `fetchLatestMessageWithChatThreads` | 未覆盖 | - |
| `getEventHandler` | 未覆盖 | - |
| `joinChatThread` | 未覆盖 | - |
| `leaveChatThread` | 未覆盖 | - |
| `removeEventHandler` | 未覆盖 | - |
| `removeMemberFromChatThread` | 未覆盖 | - |
| `updateChatThreadName` | 未覆盖 | - |

### 消息对象工厂 / 实例方法（EMMessage）

覆盖：9/16（56.25%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `chatroomMessagePriority` | 未覆盖 | - |
| `chatThread` | 未覆盖 | - |
| `createCmdSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:74<br>lib/pages/group/group_page.dart:60<br>lib/pages/single/single_chat_page.dart:26 |
| `createCombineSendMessage` | 未覆盖 | - |
| `createCustomSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:1181<br>lib/pages/group/group_page.dart:1002<br>lib/pages/single/single_chat_page.dart:663 |
| `createFileSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:1160<br>lib/pages/group/group_page.dart:981<br>lib/pages/single/single_chat_page.dart:626 |
| `createImageSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:1123<br>lib/pages/group/group_page.dart:944<br>lib/pages/single/single_chat_page.dart:561 |
| `createLocationSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:1170<br>lib/pages/group/group_page.dart:991<br>lib/pages/single/single_chat_page.dart:644 |
| `createReceiveMessage` | 未覆盖 | - |
| `createSendMessage` | 未覆盖 | - |
| `createTxtSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:735<br>lib/pages/group/group_page.dart:543<br>lib/pages/single/single_chat_page.dart:497 |
| `createVideoSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:1135<br>lib/pages/group/group_page.dart:956<br>lib/pages/single/single_chat_page.dart:583 |
| `createVoiceSendMessage` | 已覆盖 | lib/pages/chatroom/room_page.dart:1149<br>lib/pages/group/group_page.dart:970<br>lib/pages/single/single_chat_page.dart:606 |
| `groupAckCount` | 未覆盖 | - |
| `pinInfo` | 已覆盖 | lib/pages/single/single_chat_page.dart:108 |
| `reactionList` | 未覆盖 | - |

### 会话对象方法（EMConversation）

覆盖：4/25（16.00%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `appendMessage` | 未覆盖 | - |
| `deleteAllMessages` | 未覆盖 | - |
| `deleteLocalAndServerMessages` | 未覆盖 | - |
| `deleteLocalAndServerMessagesByTime` | 未覆盖 | - |
| `deleteMessage` | 未覆盖 | - |
| `deleteMessageByIds` | 未覆盖 | - |
| `deleteMessagesWithTs` | 未覆盖 | - |
| `getLocalMessageCount` | 未覆盖 | - |
| `insertMessage` | 未覆盖 | - |
| `lastReceivedMessage` | 未覆盖 | - |
| `latestMessage` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:362 |
| `loadMessage` | 已覆盖 | lib/pages/single/single_chat_page.dart:305 |
| `loadMessages` | 未覆盖 | - |
| `loadMessagesFromTime` | 未覆盖 | - |
| `loadMessagesWithKeyword` | 未覆盖 | - |
| `loadMessagesWithMsgType` | 未覆盖 | - |
| `loadPinnedMessages` | 未覆盖 | - |
| `markAllMessagesAsRead` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:424 |
| `markMessageAsRead` | 未覆盖 | - |
| `messagesCount` | 未覆盖 | - |
| `remindType` | 未覆盖 | - |
| `searchMsgsByOptions` | 未覆盖 | - |
| `setExt` | 未覆盖 | - |
| `unreadCount` | 已覆盖 | lib/pages/conversation/conversation_list_page.dart:354 |
| `updateMessage` | 未覆盖 | - |

### 初始化配置（EMOptions）

覆盖：1/10（10.00%）

| API | 状态 | 证据 |
| --- | --- | --- |
| `enableAPNs` | 未覆盖 | - |
| `enableFCM` | 未覆盖 | - |
| `enableHonorPush` | 未覆盖 | - |
| `enableHWPush` | 未覆盖 | - |
| `enableMeiZuPush` | 未覆盖 | - |
| `enableMiPush` | 未覆盖 | - |
| `enableOppoPush` | 未覆盖 | - |
| `enableVivoPush` | 未覆盖 | - |
| `withAppId` | 未覆盖 | - |
| `withAppKey` | 已覆盖 | lib/common/mixins/login_logic_mixin.dart:33 |
