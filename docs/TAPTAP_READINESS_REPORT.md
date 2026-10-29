# WordRogue Android 构建与 TapTap 试玩就绪检查

核查日期：2026-10-12。原工程：`D:\项目\1`。目标：免费开放试玩，无内购；用户告知开发者已认证、游戏尚未创建。

## 结论

**已生成实际 Android ARM64 Release 试玩 APK，安装包技术检查通过。当前仍不能认定可直接在 TapTap 开放下载：缺实名认证/防沉迷、隐私合规资料、平台应用配置与 Android 真机验收。没有上传或提交审核。**

TapTap [快速指南](https://developer.taptap.cn/docs/store/standardies-operation/)列出离线、无内购的开放试玩路径，但没有免除防沉迷及隐私合规。免费试玩不能理解为绕过所有资质；正式收费/内购不在当前目标内。

## 1. APK 实际信息

| 项目 | 实际结果 |
| --- | --- |
| 文件 | `WordRogue-v1.9-android-arm64-preview.apk` |
| 大小 | 40,090,254 字节 / 38.23 MiB |
| SHA256 | 见随包 `APK_MANIFEST.json` |
| 引擎 | Godot 4.7.2.stable.official.ed1daf0bf |
| 包名 | com.wordrogue.demo，首次公开发布前仍须确认 |
| 名称 / 版本 | 遗忘书塔 / 1.9，versionCode=1 |
| 系统 / ABI | Android 7.0+ / API24，arm64-v8a；仅 ARM64 |
| 目标 SDK | 36，来自官方预编译模板 |
| 图形要求 | OpenGL ES 3.0；Compatibility；横屏 |
| 签名 | 项目独立 RSA3072 试玩密钥；v2/v3 校验通过 |
| 原生库对齐 | ZIP 16KB 与两份 ELF PT_LOAD 16KB 校验通过 |
| 清单权限 | 无 uses-permission，包括无 INTERNET |
| 系统自动备份 | allowBackup=false |

整体依然不是 5MB。安装包体积主要包含原生引擎与运行资源；工具下载体积不算进 APK。[TapTap 打包规范](https://developer.taptap.cn/docs/store/release/publish/bundle/)要求 ARM64，本包已满足该项；未发现通用的整包 5MB 限制。

## 2. 保护与环境

- 只读取当前原工程并建立独立副本，未覆盖昨晚变更过的 project.godot。
- 构建位置：`C:\Users\Administrator\Documents\Codex\2026-10-11\files-pasted-by-the-user-wordrogue\android_release_tools`。
- 当时源码备份：`build/source_before_android.zip`；原工程源码/资源与原 project.godot 的最终哈希比对全部一致。
- 真实学习存档和音量文件前后哈希一致。所有导入与检查使用隔离 APPDATA/LOCALAPPDATA。
- Temurin JDK17.0.20.1+1、Google Build-Tools35.0.1、Platform-Tools37.0.1、Android Platform35 与匹配的 Godot Android Release 模板仅解压到独立目录。没有改系统 PATH、原 Java8 或安装 Android Studio/NDK/无关框架。
- JDK 完整 SHA256、Google 官方 SDK 仓库 SHA1 与 APK 模板成员 CRC/长度已核对；模板只按范围下载 Android 成员，不声称验证了整份所有平台模板 SHA。

签名私钥与生成密码在构建目录的 `private/` 中，**不包含在 APK、分发 ZIP 或报告内**。请所有者单独备份该目录，勿公开。证书 SHA256：`b7d395f1b55bbc0cf83d2d3599b093d49fed45940a447cbbc40c32b3c5d1b306`。这是本地试玩签名，不冒称已由平台绑定；公测前确定长期包名与签名。

## 3. 实际修改与修复

仅独立安卓副本的配置：保持16:9比例、横屏、触摸映射、Android 纹理导入支持、官方模板路径及独立签名。现有返回键/后台暂停、中文字体、施法、学习和音量代码原样沿用。

新建原生 SVG 魔法书图标，避免 Godot 默认图标。1024 PNG 候选随包提供；没有 AI 重画角色或背景，仍需所有者确认图标。原工程没有写入此候选素材。

静态清单发现 FileProvider 与 InitializationProvider 被官方非 Gradle 导出器改成相同 authority。核对 [4.7.2 官方导出源码](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/export_plugin.cpp)后，对最终包仅修正后者为 `com.wordrogue.demo.androidx-startup`，重新对齐与签名。未修改模板/引擎或游戏逻辑；全部 APK 游戏资源字节与之前受检资源一致。重建时必须执行 `finalize_apk.ps1`，不能只拿初次 export 输出当最终包。

## 4. 真正执行的检查

- `Godot --headless --editor --import`：独立工程导入通过。
- `Godot --headless --export-release`：实际 APK 导出通过。
- `apksigner verify --verbose --print-certs`：独立签名 v2/v3 PASS。
- `zipalign -c -P 16 -v 4`：PASS；APK ZIP CRC PASS。
- `aapt dump badging / permissions / xmltree`：包名、API、横屏、无调试标志、无权限、可导出的 MAIN/LAUNCHER 别名和修正后唯一 provider authority 已核对。
- 检查两个 ARM64 ELF 的加载段对齐，均16KB。
- 将 APK 实际 assets 提取为资源包，用同版本桌面 Godot做22项加载检查：标题、120/1500词库、全部7张敌人立绘/旧怪回退源、主角、中文/音标字体、六首真实 BGM、音效映射与音乐增益 JSON，全部 PASS。**这是实际 APK 资源检查，不是 Android 真机启动测试。**
- 包中未发现备份、测试、录像、私钥或真实存档。
- ADB 当前授权/未授权设备均为0，没有安装或运行 Android 真机；没有声称手机触摸、性能、音质或 Android 返回键已通过。

Godot 提示官方模板目标SDK36与本机签名工具35.0.1不完全相同，使用35.0.1回退；导出与最终签名/对齐已通过。后续 Gradle/TapSDK 接入应补齐对应 API36工具链。生成 PNG 的离线 SVG 工具有“源文件读取不适合导出”的提示，仅用于素材制作；该工具未进入 APK。

## 5. TapTap 就绪清单

| 条件 | 当前状态 / 后续动作 |
| --- | --- |
| 开发者认证 | 用户确认已完成；未登录后台代核验 |
| 创建游戏 | 尚未创建，见 `TAPTAP_SUBMISSION_DRAFT.md` |
| 免费试玩路径 | 用户已选择，保持无收费/内购 |
| 包名/版本/独立签名 | 技术可用，包名与长期签名待首次提交前确认 |
| 实名认证与防沉迷 | **阻塞下载审核：尚未接入，无验证视频** |
| 隐私 | **阻塞：缺正式主体、公开链接、游戏内说明和合规检测**；仅有本地草稿 |
| TapSDK 应用配置与更新 | 尚未创建应用/未接入；创建后按所选试玩流程确认必接项 |
| 备案/核准 | 当前是无联网权限离线包；接入实名联网服务后重新核查，以所选后台流程及官方工单结论为准 |
| 真机 | **待完成**：安装、触摸、后台、返回、音量、Mastery重启保留 |
| 宣传素材 | 有1024图标候选，仍缺合规宣传图、三张手机核心玩法截图与手机视频 |
| 素材权利 | 音频/字体/词库已保留来源许可；用户立绘/背景的授权证明待补 |

上表依据 [审核细则](https://developer.taptap.cn/docs/store/release/publish/agree/)、[安全合规规范](https://developer.taptap.cn/docs/store/release/policy/policy-guide/)、[物料规范](https://developer.taptap.cn/docs/store/release/publish/material/)逐项核查。没有把个人判断当作平台批准。

## 6. 下一步最短路径

1. 把 APK 发到 ARM64 安卓手机试玩，记录返回、后台、触屏、字号、音效及重启保存的问题。
2. 在已认证后台创建游戏，先保存未发布资料；确认最终包名和运营主体。首次创建可以先预约/敬请期待，不能等同开放下载。
3. 返回应用标识/公开 Client ID 和防沉迷服务开通状态，不发送账号密码、Client Secret 或私钥；接入真实服务后复核联网和隐私声明。
4. 补齐主体/联系邮箱和可访问隐私页面、真机媒体及素材权利说明，再按 [官方创建与测试步骤](https://developer.taptap.cn/docs/store/release/publish/create-game/)提交。

到此交付，不新增地图、词库、技能、登录伪实现或其他玩法。
