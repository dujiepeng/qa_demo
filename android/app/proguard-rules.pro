# 环信 SDK 混淆规则
-keep class com.hyphenate.** {*;}
-dontwarn com.hyphenate.**

# 忽略缺失的第三方推送 SDK 类警告
-dontwarn com.xiaomi.**
-dontwarn com.meizu.**
-dontwarn com.heytap.**
-dontwarn com.vivo.**
-dontwarn com.google.android.gms.**
-dontwarn com.huawei.**
