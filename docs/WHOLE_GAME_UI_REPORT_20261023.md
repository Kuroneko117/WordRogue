# 全流程魔典 UI 改造交付 · 2026-10-23

## 工程与保护

- 工程：`D:\项目\1`；Godot **4.7.2.stable.official.ed1daf0bf**，原生 Control/Container/Theme，Compatibility 渲染。
- 基线提交：`ef6a610`；开发分支：`ui/whole-grimoire-20261023`。
- 本轮备份：`backups/whole_ui_20261023/`，保存脚本、场景、UI素材、配置、测试、README与真实学习/音量文件；原始全部正式资源另由基线 Git 和上一轮工程备份保护。
- 用户原有未跟踪的截图导入记录、UID文件保留。正式 `releases/` 包、签名与渠道配置没有覆盖，没有推送或发布。
- GameState、WordBank、SaveData、AudioBus、EnemyBrain/Definitions、RouteState、词库与项目配置没有差异。真实 `wordrogue_save.json` 和 `wordrogue_audio.cfg` 与本轮备份 SHA256 一致。

## 本轮实际覆盖

| 流程 | 改造内容 |
| --- | --- |
| 标题 | 去除大灰色卡片，卷首标题/副标题与原主角对置，书签式行动按钮，保留设置与退出 |
| 难度选择 | 三档誓言藏页、罗马卷号、独立试炼徽记、推荐文字和旧金皮革材质；说明全部保留 |
| 地图探索 | 书塔星盘、圆规/刻度、分段路线、金属节点封印；行囊独立附页，原路径和键盘导航保留 |
| 普通/精英/Boss战 | 保留上一轮单词羊皮纸、三法术、卷轴答案和角色站位；统一世界边饰与精英/Boss入场魔典框；紧凑HUD不使用大型书脊，避免压住生命/意图 |
| 奖励/藏宝 | 三件遗物藏页、品质文字刻印、徽记、完整效果说明与收入魔典按钮；领奖高亮不再变回平面灰卡 |
| 事件/事件答题 | 异闻章节、正文/选择双页与代价提示；正文采用窄金属边框，保持长说明和禁用理由清楚 |
| 回忆书房 | 左侧复习规则/恢复/掌握度附页，右侧魔典答题页；原四选一与恢复规则保留 |
| 休息 | 真羊皮纸页面、休息徽记与生命恢复预览；保留一次使用与返回地图 |
| 暂停 | 旅途书签菜单、魔典皮革、章节徽记，继续/设置/重开/返回/退出均保留 |
| 声音设置 | 深蓝皮革铭文页；独立音乐/音效滑轨、菱形抓手、刻度、百分比/已静音提示；试听、默认值、返回保留 |
| 二次确认 | 同一材质的危险操作确认页，取消与确认清楚，长期记录说明保留 |
| 胜败结算 | 冒险日志纸面摘要，提升与复习双栏；长词单独滚动，统计/标题/再来一局固定 |
| 公共细节 | 全局边饰、纹理按钮普通/悬停/按压/禁用/聚焦、工具提示、金色滚动条、细金分隔线 |

这轮主要改变页面构图、材质和阅读层级，未增加玩法、调整数值或更换正式角色。

## 美术与来源

- 方向沿用用户的 `设定参考图/battle_ui_target.png`，并复用上一轮通过的独立纸张、法术图标、符文与金属边框。没有将参考整图放进运行界面。
- 新增 **`assets/ui/grimoire/leather_cover.png`**：内置图像生成工具生成无文字深蓝皮革古籍封面，经保持比例的尺寸规范化。源 PNG 约1.25MiB；原稿保留在备份的 `leather_cover_master.png`。作为独立可伸缩表面使用，不是带文字的整页截图。
- 原创代码装饰：`journal_vignette.gd`（章节/遗物封印）、`library_chrome.gd`（世界边饰）、`flow_folio.gd`（装饰规则、SVG滑轨抓手）。保留可编辑源。
- 所有中文字、词汇、音标、HP、法力、统计、代价与按钮文字均为 Godot 动态文字。浅纸面配深墨字，皮革配纸色字。
- 本轮没有外站下载、付费 API、模型安装或引擎升级；复用既有字体与中文回退。新素材来源及哈希已补入 `assets/ui/grimoire/manifest.json`。
- 沿用本地目标图与实机观察形成规范，未把未经核实的竞品印象写作事实。具体方案见 `ui-visual-spec.md`。

## 修改文件

### 原文件

`scripts/main.gd`（统一世界边饰、入场表面与领奖反馈），以及 `scripts/ui/` 下：

`ui_kit.gd`、`archive_panel.gd`、`archive_button.gd`、`battle_theme.gd`、`battle_view.gd`、`journal_screens.gd`、`pause_menu.gd`、`event_view.gd`、`review_view.gd`、`route_view.gd`、`map_icon.gd`。

### 新文件

- `scripts/ui/journal_vignette.gd`
- `scripts/ui/flow_folio.gd`
- `scripts/ui/library_chrome.gd`
- `tests/whole_ui_visual.gd`：原有完整UI测试的独立副本，增加暂停/确认/首领入场截图，原测试保留。
- `tests/whole_ui_review.gd`：受影响页面与长日志定向复验。
- 新素材及来源记录、本报告、`ui-visual-spec.md`、`ui-comparison.md`、两位工程说明、独立 `whole_ui_visual_qa.md`。

## 运行与检查证据

所有运行重定向到 `.local_test/whole_ui_profile/`，图形截图为真实 Godot 窗口渲染，1280×720 和1920×1080；不是Figma图或合成演示。主代理整合，两位工程子代理分别负责 Journal 和流程页，独立QA代理只查看截图/写报告，没有改工程。

| 阶段 | 实际结果 |
| --- | --- |
| 基线 | 保存此前实际全流程截图到 `.local_test/whole_ui/before/` |
| 导入检查 | 发现并修复新脚本类型推断与 `Skin` 原生类重名；最终导入无脚本错误 |
| 首轮截图 | 35张，两种分辨率；1616项布局检查中6项失败，定位难度/地图/奖励底部溢出 |
| 第二轮截图 | 修复间距与边距后35张、1616项布局检查0失败；独立QA继续发现雕花压字，未将该计数等同视觉通过 |
| 唯一一次完整路线回归 | 1803项，2项失败，均为胜利报告底部按钮边界；原生七层路线实际通关，31题、25个不同词、首领二阶段及结算验证成功 |
| 最终定向复验 | `whole_ui_review.gd` **456项、0失败、14张截图**，复验难度、奖励、事件、设置及长词双栏；两列均验证可实际滚动，按钮留在画布内 |
| 真实存档 | 两个真实数据文件与备份哈希一致；核心数据脚本无差异 |

实际调用：

```powershell
# 引擎均为 D:\godot\Godot_v4.7.2-stable_win64_console.exe
--headless --editor --path D:\项目\1 --import
--path D:\项目\1 --resolution 1280x720 --max-fps 120 --script res://tests/whole_ui_visual.gd -- --captures-only
--path D:\项目\1 --resolution 1280x720 --max-fps 120 --script res://tests/whole_ui_visual.gd
--path D:\项目\1 --resolution 1280x720 --max-fps 120 --script res://tests/whole_ui_review.gd
```

执行上述测试时需像原测试一样设置隔离 APPDATA、LOCALAPPDATA 和 `WORDROGUE_TEST_PROFILE=1`；脚本会拒绝真实用户目录。完整回归后仅修正反馈中确认的页面，用定向测试复验，没有重复大量平衡模拟。

日志：`.local_test/whole_ui/round1.log`、`round2.log`、`regression.log`、`focused.log`。原回归覆盖原生输入/答题单次结算、三法术、HP/Combo/护盾、八种敌人、ESC/暂停、音量/独立静音/设置保存、死亡和再开、音乐不叠播及缺图回退。

## 视觉修正与验收范围

1. 首轮出现皮革金属角花覆盖正文：扩大阅读区，较窄的战斗HUD、行囊、书房规则和事件正文使用克制的金属边框；皮革封面保留给适合的卷页。
2. 难度/奖励/地图页过高：调整空白、徽记尺寸和图例节奏，完整保留内容及字体。
3. 设置文字/刻度贴边：给音量铭牌独立内距，主书页标题避开书脊。
4. 报告长列表撑页面：两列使用独立滚动区域，保留全部显示数据，固定统计和主要行动。
5. 纸面文字对比：统一深墨文字，增加两侧净空，避免浅色字落在浅纸上。

独立视觉审核最终结论为 **VISUAL PASS：已审看的 Windows 1280×720、1920×1080 全流程布局**。残余项详见 `whole_ui_visual_qa.md`。功能、视觉、性能与发布是不同门禁，本报告不声称移动设备性能或商店审核通过。

## 画面交付

- [标题](whole_ui_review/title.png)
- [试炼选择](whole_ui_review/difficulty.png)
- [地图与行囊](whole_ui_review/map.png)
- [设置](whole_ui_review/settings.png) · [设置改造前](whole_ui_review/before_settings.png)
- [遗物奖励](whole_ui_review/reward.png)
- [回忆书房](whole_ui_review/memory.png)
- [休息书桌](whole_ui_review/rest.png)
- [事件/生命代价](whole_ui_review/event_disabled_cost.png)
- [长词日志压力夹具](whole_ui_review/report_long_lists.png)

完整两分辨率证据保留在 `.local_test/whole_ui/round2/` 和 `final/`。`report_long_lists`/`report_scrolled`为8条重复长词的UI压力夹具，其0/7层或统计不是实际通关记录；真实31题通关保留在 `round2/report_win.png` 和 `round2/ui.json`。部分原有施法测试将敌HP提高到1000避免提前结束，也属于测试夹具，不代表正式数值。

## 已知差异与试玩建议

- 已覆盖完整界面流程，仍未逐像素复刻概念图。徽记以原创矢量为主，距离手绘法术纹章仍有材质差距；部分皮革金属角饰和极短说明的留白仍可精修。
- 地图01/07层号仍贴近角饰；日志底部淡纹处黑字可辨。长词单已验证可滚动100px，末项的逐条人工导航仍待试玩确认，不宣称所有条目已人工遍历。
- 继续使用现有正式角色、背景及音乐；本轮没有重新配音或重绘环境。连续游玩手感和个人显示器上的小字舒适度需人工判断。
- 验证目标为PC的1280×720、1920×1080，未进行Android真机触控、安全区、性能或重新导出验收。
- 历史发行EXE/APK/Web包未覆盖。请用Godot 4.7.2打开当前 `project.godot` 启动查看新界面。

建议只试玩一条路线：标题→选择试炼→地图→战斗/奖励→事件/书房→首领→日志；中途ESC调整两条音量与静音、取消一次返回标题确认，检查长词日志滚动。不再自动扩展新功能。
