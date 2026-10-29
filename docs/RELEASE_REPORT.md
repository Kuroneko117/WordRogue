# WordRogue V1.9 发布准备与体积优化报告

日期：2026-10-11。工程：`D:\项目\1`。

## 1. 完成状态

**Windows Release 已实际导出并运行。Android 仅完成基础适配与导出预设，因环境缺失尚未生成 APK。没有实施微信小游戏移植或提交应用商店。**

当前引擎为 Godot **4.7.2.stable.official.ed1daf0bf**，Compatibility 渲染，GDScript。没有 Git 仓库。原始图片、音乐、词库、数值与真实存档保留。

## 2. 990MB 的来源

开发前工程共约 990.13 MiB，其中 `.local_test` 691.43 MiB（录像、测试数据与截图等）、`backups` 204.45 MiB、`.godot` 45.98 MiB、实际 assets 32.92 MiB、参考图 13.67 MiB。代码与词库不到 2 MiB。

初版几十 KB 是脚本与少量 JSON 的体积，未计入 Godot 运行引擎及后来加入的正式美术、音乐。整个开发目录不能作为玩家下载包。

本轮保留历史备份，没有删除那 990MB。新的模板、发布工程和测试证据也会占用开发硬盘空间；优化对象是**分发包**，不是用删除备份伪造工程变小。

## 3. 实际产物与大小

位置：`releases/windows/`，压缩包：`releases/WordRogue-Windows.zip`。

| 组成 | 大小 |
| --- | ---: |
| WordRogue.exe（官方 Windows 64 位 Release 引擎） | 109,268,480 字节 / 104.21 MiB |
| WordRogue.pck（游戏代码与运行资源） | 14,168,832 字节 / 13.51 MiB |
| 完整 ZIP（Deflate 9） | 51,184,504 字节 / 48.81 MiB；哈希见 `releases/BUILD_MANIFEST.json` |
| 解压运行目录 | 约 118 MiB |

包含一个约 194 KiB 的控制台封装用于排查问题，日常双击 `WordRogue.exe`。压缩包包含所有运行文件和许可证，**不含玩家存档**。附 `releases/WordRogue-release-source.zip` 精简可运行 Godot 工程（32,164,776 字节 / 30.67 MiB），方便审阅或迁移；它保留源图，不能与 PCK 的导入压缩体积混淆。

**没有达到整体 5MB，不把引擎体积隐去，也不把源代码体积当作可运行游戏下载体积。** 未定制编译引擎，未将资源改为联网下载。

## 4. 实际优化

- 从白名单复制 scripts/scenes/data/assets 建立 `.local_test/release/staging_mobile` 独立运行工程，排除备份、录像、截图、参考图、测试、工具及代理守护程序。
- 仅在发布工程使用 Godot 原生有损 WebP 纹理导入，质量 0.82；背景最长边 1280，角色 1024，敌人 768。保留透明通道与宽高比，源图片字节未修改。1280×720 适配优先，1920×1080 会略少于源图细节。
- 排除 `assets/enemies/library_battle.png` 的未使用重复副本；与保留的 backgrounds/library_battle.png SHA256 相同。原工程两份均保留。
- 发布复制品的 JSON 去掉缩进，解析后值严格一致，不删词汇、释义或学习逻辑。
- 六首真实 OGG 与现有 WAV 原样保留，沿用其导入压缩。不谎称完成音乐重编码。机器自带 FFmpeg 为视频专用裁剪版，缺少 Vorbis 解码/编码，不适合本项目音乐优化；未为此安装额外工具。
- 显式包含动态加载的 JSON、图像、音频及字体清单，避免仅导出场景依赖时丢资源。

## 5. 字体与手机接入准备

新增 Noto Sans SC 中文子集及 Noto Sans 音标 / Symbols 2 装饰字符补充，均为 SIL OFL 1.1，实际来源、下载 SHA256、包含文字与许可证见 `assets/fonts/manifest.json`。

完整验证 120 与 1500 两套词库中实际英文、中文释义和音标的字形覆盖。新增文字需要更新子集；缺少字体文件仍回退系统字体。奖励图标主体继续使用程序绘制。

支持 `-- --touch-ui` 的桌面预览，Android/iOS 自动使用点击提示；手机横屏、16:9 保持比例、触摸映射、Android 返回键暂停、应用后台保存并暂停已准备。没有更改三法术、敌人、蓄势、奖励、地图、Mastery 或 BGM 音量计算。

新字体使战斗卡片最低高度增加，真实 EXE 截图暴露了底部信息越界，已收紧中央卡片上下留白、间距、空弱词行及反馈区域；底部完整显示，两种分辨率检查通过。

## 6. 修改范围

- `project.godot`：保持比例与横屏、触摸输入映射；config/name 不改，继续使用原 user:// 位置。
- `scripts/ui/platform_ui.gd`：平台文字判定与字体加载/回退。
- `scripts/main.gd`：字体、系统返回键、后台保存与暂停。
- `scripts/ui/screen_base.gd`：字体类型支持 FontFile。
- `scripts/ui/pause_menu.gd`：复用统一返回行为，保留 ESC 与原确认菜单。
- `scripts/ui/battle_view.gd`：触屏提示和必要留白调整。
- `scripts/ui/route_view.gd`、`journal_screens.gd`、`review_view.gd`：触屏文字。
- `export_presets.cfg`：Windows Release 与待补齐环境的 Android arm64 预设。
- `tools/fetch_release_assets.py`、`prepare_release.py`、`build_release.ps1`：可重复资源准备、隔离工程与导出。
- `tests/release_check.gd`、`release_gui.py`：外部测试；不进入玩家包。
- `assets/fonts/`、`assets/licenses/`：字体与引擎版权说明。

SaveData、WordBank、GameState、原始词库、美术和音频逻辑未修改。

## 7. 保护与模板来源

变更前可恢复备份：`backups/v19_before_release_20261011_194717`，包括将修改的主要文件及最新真实学习/音量存档。没有修改该备份。复习页仅把键盘说明按平台改为点击说明；可按源码 diff 恢复这行文字。

自动审批曾拒绝向既有备份补写该文件，理由是可能损害恢复备份。没有绕过或覆盖，后续正常构建不受影响。

真实存档最终 SHA256 与任务前一致：

- 学习存档：`6BE4D3208E9DCF0E486F29F3AF10C072C0DF2F8904F2045C4C9C4FC9AAB52AD6`
- 音量设置：`6ECD0AC4139BDCDE18BA6FF7196E5DC350CCE8854D8D09270D7F34CFEDB8706C`

只下载官方 [Godot 4.7.2 模板](https://github.com/godotengine/godot-builds/releases/tag/4.7.2-stable) ZIP 内 Windows Release 成员（按范围获取约 36 MiB，不下载 1.19 GiB 所有平台模板）。检查成员长度和 CRC32；不声称验证了整个 ZIP 的 SHA256。模板 SHA256 为 `d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562`。下载用了正常 TLS 校验，没有全局安装模板或更改系统设置。

## 8. 实际测试

主要命令（全部隔离 APPDATA/LOCALAPPDATA，并设 WORDROGUE_TEST_PROFILE=1）：

```powershell
tools/build_release.ps1 -Stage '.local_test\release\staging_mobile'
Godot_v4.7.2-stable_win64_console.exe --path '.local_test/release/staging_mobile' --script 'D:/项目/1/tests/release_check.gd' -- --touch-ui
Godot_v4.7.2-stable_win64_console.exe --headless --path '.local_test/release/staging_mobile' --script 'D:/项目/1/tests/smoke.gd'
WordRogue.exe -- --touch-ui
python tests/release_gui.py start
python tests/release_gui.py pause
python tests/release_gui.py settings
```

- 真正 Windows Release 导出成功，非复制编辑器冒充发布版。
- 独立发布工程 50 项针对检查 PASS：两套词库、中文/音标、六首音乐、现有音效映射、所有敌人/回退、三法术动画后继续答题、原生暂停、返回键行为、后台通知、静音、两种分辨率答案/底部边界。
- 既有 smoke PASS：120词、四场固定基线核心流程及其奖励/报告/学习持久化。没有重复大量平衡模拟。
- 实际导出 EXE 原生 GUI：标题→难度→地图→战斗，点击守护并作答，进入下一题，暂停按钮和声音设置均确认。原生截图位于 `.local_test/release/exe_qa/`，独立工程 1280/1920 截图位于 `.local_test/release/qa/`。
- 初次检查发现音标缺字与字体引起底部越界，已修复后复测。最终检查日志未出现 Parser/资源路径/空实例错误。

官方 Release 模板禁止路径覆盖，也不提供编辑器的外部脚本启动方式；逻辑自动检查实际使用同一发布工程的编辑器运行，实际 EXE 用窗口点击和截图确认。两者分别记录，不将编辑器自动检查冒称 EXE 脚本测试。

## 9. 未完成与人工验收

- 未生成 Android APK，缺 JDK17、SDK、4.7.2 Android 模板与发布签名；详见 `docs/ANDROID_RELEASE_READINESS.md`。没有 Android 真机、安装大小或商店审核结果。
- 未实施微信适配。先完成原生安卓更符合当前工程；微信需要独立兼容与分包验证，不能直接上传 Windows ZIP。
- Windows EXE 未签名；是可玩的独立试玩包，不能等同于 TapTap 安卓上架包。
- 音乐未重编码，仍占游戏资源大部分。若再缩小资源包，应在试听授权后对独立发布副本降低 Vorbis 码率，而非删掉曲目或改用户音量。
- 请人工听音乐/音效，观察 1920×1080 下 WebP 细节和透明边缘，并在最终 APK 出来后验收手机字号、触摸、系统返回与后台恢复。

本轮到此停止，没有继续增加玩法。
