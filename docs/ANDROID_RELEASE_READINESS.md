# Android / TapTap 发布准备

## 本轮状态

已完成横屏、触摸鼠标映射、触屏文字、返回键暂停、系统进入后台时保存并暂停、独立中文与音标字体、arm64 导出预设。上述逻辑已在 Windows 触屏界面预览中检查，**尚无 APK 和 Android 真机测试结果**。

实际检测：PATH 的 Java 为 1.8.0_321；没有 Android SDK、adb、匹配的 Android 导出模板或发布 keystore。Windows 模板不会生成 Android APK。

## 需要的环境

以 [Godot 官方 Android 导出文档](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html) 为准。当前文档推荐 OpenJDK 17，并列出 Platform-Tools 35+、Build-Tools 35.0.1、Platform 35、最新 Command-line Tools，以及对应的 CMake/NDK。

下一步先确认可否下载这些必需工具，优先独立工具目录，不修改当前 Java 8 或 PATH，不安装无关框架。使用 Godot 4.7.2 相匹配的 Android 模板，验证完整性。发布签名由项目所有者管理，不在工程、报告或 ZIP 中放入密码和私钥。

`export_presets.cfg` 中的 `Android Release (SDK required)` 是准备配置，未导出成功；应用包名 `com.wordrogue.demo` 为待提交确认的开发占位，不能解释为已通过商店审核。未声明联网权限。

## APK 出来后需要检查

- 横屏与长屏比例、切后台恢复、Android 返回键、双指触摸期间一次答题只结算一次。
- 中文、音标、所有敌人、护盾/蓄势、音量滑块、静音、退出重启后的本地记录。
- 真机 FPS、兼容性、声音、安装体积、低端机纹理内存。
- 确认包名、版本、图标、发布签名及 TapTap 开发者后台当时的提交要求。

本轮没有接入平台登录、广告、付费或网络服务，没有提交商店或实施微信适配。Windows 包大小不能直接当作 APK 大小。完整 Godot 桌面/安卓包不能承诺 5MB；微信小游戏首次加载额度与整个游戏资源量须分开计算。
