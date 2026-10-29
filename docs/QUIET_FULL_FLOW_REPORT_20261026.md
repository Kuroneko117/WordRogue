# 全流程克制扉页风格统一

日期：2026-10-26。工程 `D:\项目\1`；Godot `4.7.2.stable.official.ed1daf0bf`。

## 方向与保护

用户认可新标题页风格，指出其他页面与之割裂。本轮以该实际标题画面为共同基准，统一全流程表现，不新增玩法或生成另一套整屏插画。

后续核查更正：统一 UI 时曾将地图背景优先指向普通战斗长廊，现已恢复原主图书馆背景；新版标题保留认可的长廊构图。原六张背景资源及其他场景映射未删除、未覆盖。`quiet_flow_review/map.png` 已更新为恢复后的实机图。

背景更正实际验证：在隔离配置中调用现有场景背景解析并检查标题、地图、普通、精英、Boss、回忆/休息、事件/藏宝及报告，11 项检查、0 失败，另保存一张 1280×720 地图实机图；日志 `quiet_flow_review/scene_preservation.log`。本次没有恢复或覆盖真实存档。真实学习档在此前一轮交付之后已有新的写入，保留当前文件，不拿旧校验记录回滚玩家进度。

- 基线 commit：`b57f62e`。
- 开发分支：`ui/quiet-full-flow-20261026`。
- 源脚本、场景、工程配置及修改前记录：`backups/quiet_flow_20261026/`。
- 原有未提交文件保留，没有推送或修改正式发布包。
- 真实学习文件 `wordrogue_save.json` 与音量文件 `wordrogue_audio.cfg` 的最终 SHA256 均与修改前一致。

## 已完成

| 范围 | 实际改动 |
| --- | --- |
| 共用系统 | 新增 `quiet_style.gd`，集中墨蓝、纸白、旧铜及语义色；统一暗纸、短线焦点、按钮状态与背景调色 |
| 标题 | 保留已认可构图、书塔标记及原生菜单，接入同一颜色定义 |
| 难度与奖励 | 克制三栏、章节编号、小墨印、书脊细线；去除皮革、亮纸和包围金框，保留推荐与奖励品质信息 |
| 地图 | 统一背景、字体与行囊样式；移除大星盘与光边，保留路线、图标、状态、收益预览与键盘焦点 |
| 战斗 | 开放式生命/意图 HUD，暗纸单词、细线答案、小型线条法术图标，平直血条和低亮地面光环；保留全部立绘与战斗演出 |
| 精英与首领 | 保留专属立绘、蓄势及警报；入场标题改为共用衬线字体，暗色表面一致 |
| 事件与回忆 | 暗色书页、纸白正文与明确的收益/成本，保留四选一和原回调 |
| 休息 | 留白双栏与动态生命变化说明，原恢复公式不变 |
| 暂停、设置、确认 | 共用暗色章节页、无框菜单、细滑轨与小抓手；保留音量、静音、保存与 ESC 行为 |
| 学习报告 | 暗色摘要、完整统计和独立滚动的提升/弱词列表，保留再玩与返回 |

没有改写已有角色或背景图片，没有下载资源、调用图像生成器、增加软件或费用。旧 UI 素材保留供回退与历史版本恢复；当前控件不再调用旧皮革或亮卷轴表面。原法术特效、音频、输入和答题流程沿用。

## 主要修改文件

- `scripts/ui/quiet_style.gd`、`ui_kit.gd`、`battle_theme.gd`：共同样式与状态。
- `scripts/ui/archive_panel.gd`、`archive_button.gd`、`archive_emblem.gd`、`library_chrome.gd`：去除旧装饰并统一交互。
- `scripts/ui/battle_view.gd`、`battle_button.gd`、`battle_stage_light.gd`：战斗表现。
- `scripts/ui/frontispiece_title.gd`、`journal_screens.gd`、`journal_vignette.gd`、`reward_badge.gd`、`archive_reward_style.gd`：标题与日志系列页面。
- `scripts/ui/pause_menu.gd`、`flow_folio.gd`、`route_view.gd`、`map_icon.gd`、`event_view.gd`、`review_view.gd`：流程页面。
- `scripts/ui/screen_base.gd`：仅调整视觉颜色常量。
- `scripts/main.gd`：仅调整背景绘制/映射、字标、词卡装饰文本、奖励高亮强度及入场字体，原结算与状态机不变。
- `tests/quiet_flow_input.gd`：聚焦实机检查。
- README、当前规范及两份实施说明已更新。

`game_state.gd`、`word_bank.gd`、`save_data.gd`、`audio_bus.gd`、怪物定义、地图状态、事件状态、奖励目录、词库及 `project.godot` 均无本轮差异。

## 实际测试

全部引擎运行使用 `.local_test/quiet_flow/profile/` 隔离 APPDATA、LOCALAPPDATA，并设置 `WORDROGUE_TEST_PROFILE=1`，没有在真实玩家配置中运行测试。

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\项目\1' --headless --editor --import
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\项目\1' --script res://tests/whole_ui_visual.gd --rendering-method gl_compatibility --max-fps 60 -- --captures-only
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\项目\1' --script res://tests/quiet_flow_input.gd --rendering-method gl_compatibility --max-fps 60
```

以上命令必须先配置隔离变量，不应直接在真实存档环境运行。

1. 导入成功，无解析、资源或 shader 错误。
2. 第一轮：35 张实机截图、1552 项布局/原资源检查、0 失败。覆盖 1280×720、1920×1080 标题、难度、地图、战斗、蓄势、奖励、事件、回忆、休息、报告与设置；另有八怪、暂停、确认和首领入场。
3. 截图检查发现战斗实心底板仍显厚重，实际修正为开放式 HUD、低透明词卡与更轻的技能表面。没有为了统一而削弱答案对比度、蓄势警示或正确/错误反馈。
4. 最终针对性检查：543 项、0 失败、10 张截图。复查两分辨率普通/精英/首领、满蓄势；实际鼠标与键盘验证标题→难度→地图→战斗、Q/W/E 选择、守护答对伤害/护盾、正确与错误重复点击只结算一次、Combo、反击、动画后恢复作答、ESC、暂停不结算、独立音量静音与保存、返回标题确认、重开清空临时遗物、奖励防重复与回到地图。
5. 没有重复运行完整数值模拟或宣称真人完整通关。本轮也没有对三法术全部伤害组合、六首 BGM 或移动设备重新做完整验收。

日志：`docs/quiet_flow_review/round1.log`、`final_input.log`。完整临时截图分别在 `.local_test/whole_ui/round2/` 与 `.local_test/quiet_flow/final/`。各目录有历史文件时，以本轮日志和 2026-10-26 的截图为准。

## 视觉证据

- [当前标题](quiet_flow_review/title.png)
- [最终普通战斗](quiet_flow_review/battle.png)
- [首领 1920×1080](quiet_flow_review/boss_1920.png)
- [设置](quiet_flow_review/settings.png)
- [地图](quiet_flow_review/map.png)
- [奖励](quiet_flow_review/reward.png)

历史对照：`docs/whole_ui_review/` 保存旧皮革版本；第一轮战斗底板截图另存 `.local_test/quiet_flow/round1/battle_1280x720.png`。

## 审查限制与已知差异

- 主代理实际查看标题、难度、地图、奖励、书房、休息、事件、报告、设置与最终普通/Boss 战斗图并修正问题。独立 QA 代理在完成报告前因额度限制中断；最终图审查由主代理完成，不冒充独立验收。
- 角色原画及部分背景内置的高密度装饰仍保留，尤其 Boss 图书馆的纹样；本轮统一的是 UI 语言和背景明暗，没有声称全部插画已经成为同一绘画风格。
- 当前方向更冷静，是否需要在休息房增加暖意与进一步完善专属字标，应由后续人工试玩和美术判断决定。
- Windows 宋体/英文衬线不随包分发，其他平台回退现有 Noto 字体时气质可能不同；未进行跨平台字体或真机验收。
- 最终用户视觉验收保持待定；功能检查计数不等于艺术质量结论。

## 如何查看

用现有 Godot 打开 `D:\项目\1\project.godot` 并运行。建议依次查看标题→难度→地图→战斗→ESC 设置，再看一次奖励、事件与报告。已经导出的旧包没有自动更新，需查看当前源工程。
