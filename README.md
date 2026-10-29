# WordRogue V1.9 — 遗忘书塔

## 2026-10-26 全流程克制扉页风格

以新标题页为基准，统一难度、地图、战斗、奖励、事件、书房、休息、暂停设置与学习报告。采用墨蓝/纸白/旧铜、衬线标题、单侧书脊线、小型图标与短线焦点；旧皮革金框与亮卷轴素材保留在工程中，不再作为当前控件表面。原生输入、玩法、立绘、BGM、词库与长期存档保持。

当前规范：[全流程视觉规范](docs/QUIET_FLOW_VISUAL_SPEC.md)。运行源工程即可查看；已有发布包未覆盖。交付及实机检查见 [本轮报告](docs/QUIET_FULL_FLOW_REPORT_20261026.md)。以下 UI 记录保留供追溯。

## 2026-10-16 UI 统一重构

主菜单、三卷难度、节点地图、战斗施法/答案页签、奖励藏页、事件书页、回忆与休息、暂停音量和冒险日志统一为“墨金藏书”视觉系统。新增刻线封面、纸页面板、按钮状态、衬线标题/数字、19 个轻量原创 SVG 与页面淡入；原战斗、词库、Mastery、地图、存档及音量逻辑保持不变。

详见 [UI 重构报告](docs/UI_PASS_REPORT_20261016.md) 与 [UI Audit](docs/UI_PASS_AUDIT.md)。运行当前 project.godot 后按 F5；旧导出包未自动更新。定向实机验证：`tests/run_ui_pass.ps1`，截图位于 `.local_test/ui_pass`。

**单词就是你的武器。** 英语四级英译中四选一 × 路线探索与随机强化 × 回合制魔法战斗。

## 当前版本：V1.9

- 默认七层分支冒险：入口战斗→五层分支/特殊房→第七层Boss。每局1–2未知事件，8怪物与5事件完整资源池保留。
- 普通HP成长每层+1、精英/Boss+2，短局基础HP配置见scripts/short_run_balance.gd；普通一奖励、精英双奖励不变。
- 标题、难度、战斗、地图、奖励、事件、回忆/休息、报告和ESC界面采用统一原生容器与Theme；地图一屏看全，行囊单独滚动。
- 新主角word_mage_v2.png已去白底并透明接入，旧主角保留回退。三法术、Tween、Mastery、词库、18遗物与独立音量保存继续使用原机制。
- 键盘：1–4作答、Q/W/E法术、Tab/方向键导航、Enter确认、ESC暂停/设置。目标普通单局7–10分钟，仍需真人计时。
- V1.8六首BGM、39个WAV和指定背景未替换；真实用户学习/音量档案已备份并验证未改。

完整交付：docs/V1.9_INTEGRATION_REPORT.md；UI规范：docs/V1.9_UI_GUIDELINES.md。
备份：backups/v18_before_v19_20261011_173018/。

Godot 4.7.2打开project.godot后按F5，或：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\项目\1'
```

定向验证（独立.local_test/v19_profile存档）：

```powershell
.\tests\run_v19.ps1 -Mode models
.\tests\run_v19.ps1 -Mode relics
.\tests\run_v19.ps1 -Mode ui
.\tests\run_v19.ps1 -Mode smoke
```

截图：.local_test/v19/1280x720与1920x1080。旧版本12层测试属于历史版本，当前默认地图使用V1.9测试。以下为历史开发记录。

## V1.8 视听完善

- 新增4首真实CC0循环BGM：标题/地图、精英、书房/休息、事件/藏宝；原普通与首领曲保留，共6首。沿用原单播放器、淡入淡出和ESC音量设置，不重设用户百分比。
- 接入用户确认的12.jpg普通长廊、13.jpg精英祭坛、14.jpg回忆/休息房；保持比例并按场景压暗。标题/地图与Boss保留主图书馆，事件/藏宝保留原祭坛（与13.jpg相同画面）。
- 从已核实CC0包实际导出18个新音效文件，改善墨水、纸书、魔典、蓝焰、锁链和重型法术；旧21文件保留，共39个WAV。声音事件仍为95个，新增的不是空事件名。
- 尘页守卫预留 `assets/enemies/dust_guard.png`，缺图继续使用原墨影PNG；原立绘、蓄势条与全部玩法不变。

交付：`docs/V1.8_REPORT.md`；许可与作者：`assets/audio/licenses/V1.8_LICENSES.md`；实际源文件/哈希：`assets/audio/v18_manifest.json`。
修改前完整备份及真实存档副本：`backups/v17_before_v18_20261010_003710/`。

```powershell
.\tests\run_v18.ps1 -Mode av
.\tests\run_v18.ps1 -Mode smoke
```

测试使用 `.local_test/v18_profile/`。真实窗口检查音乐、循环、暂停、双分辨率和攻击；无窗口20倍玩法快测关闭BGM。带音乐的加速退出诊断及尚未完全定位的解码对象告警见V1.8报告，不作为真实窗口验收结果。

## V1.7 历史视听接入

- 玩法沿用 V1.6。怪物的26种攻击改为显式视听映射：墨影用墨球/墨潮，纸页傀儡用纸拳/碎页，拟态魔典用撕咬/吸取，幽灯用蓝焰，档案官用锁链/封印/审判；首领保留古书与暗红法阵。
- 用户参考图中的书房与祭坛已接入休息/回忆、事件/藏宝界面；背景保持原比例并轻微裁切。拼版设定板与方形走廊图没有接入。
- V1.7第二阶段已接入四只新怪物的正式透明PNG，沿用等比缩放、原动画和缺图占位；敌人类型下新增金色蓄势分段条，满格红色显示“不可打断”，触发后清零并显示冷却。原主角、旧怪物、背景和两首音乐不变。
- 场景音乐分七类，一名播放器淡出/换流/淡入；精英缺曲时复用普通音乐，其余缺曲时回退标题曲或静音。当前还没有新增专用BGM。ESC独立音量、静音和自动保存保留。

规划：`docs/V1.7_STYLE_PLAN.md`；本轮报告：`docs/V1.7_REPORT.md`；资源约定：`assets/README.md`。
第二阶段交付：`docs/V1.7_STAGE2_REPORT.md`；修改前备份：`backups/v17_before_stage2_20261009_234236/`。定向双分辨率检查：`.\tests\run_v17_stage2.ps1`，使用独立测试存档。
修改前备份：`backups/v16_before_v17_20261009_223228/`。测试仅使用 `.local_test/v17_profile/`，不读取真实学习存档。

```powershell
.\tests\run_v17.ps1 -Mode import
.\tests\run_v17.ps1 -Mode av
.\tests\run_v17.ps1 -Mode capture -Resolution 1280x720
.\tests\run_v17.ps1 -Mode audit
```

## V1.6 历史玩法


开始冒险后先选择难度，再进入原十二层地图：

| 难度 | 词库 | 基础生命 / 攻击系数 |
| --- | --- | --- |
| 简单 · 学徒 | 原120词 | 0.9 / 0.8 |
| 普通 · 四级试炼（默认推荐） | 项目精选CET4核心1500词 | 1.0 / 1.0 |
| 困难 · 深渊试炼 | 同一套1500词，同词性干扰项优先 | 1.15 / 1.1 |

系数仅在生成怪物时应用一次，随后按原地图规则增加楼层生命；没有限时答题。整局难度固定，新一局可重新选择。报告显示难度、词库与事件答题数量。

- **四种新魔物**：纸页傀儡、拟态魔典、幽灯之灵、沉默档案官，使用可区分的程序美术；原怪物、正式PNG与最终首领保留。敌人按前/中/后期池生成，避免连续三场同种普通怪。
- **蓄势与预告**：连续答对打断普通攻击会增加蓄势；答错使连续计数归零。满蓄势后下一题预告不可打断攻击，答对仍可能受到60%攻击力的反击。守护先加盾再抵挡，爆发击杀可取消反击；执行后清零并至少冷却两题。
- **每局2～4个“？”房间**：遗失书页、诅咒书匣、流浪抄写员、错乱词典、墨影伏击。进入前不泄露具体事件，进入后固定结果；复习正常更新掌握度，交易和奖励仅一次。
- **离线1500词库**：来自MIT许可ECDICT的四级标签与语料词频筛选；恰好1500个不同词，有校验脚本与100词逐项抽样记录。主要词性/释义统一，干扰项过滤已知重叠与等价中文义。不是官方唯一标准词表；尚未经过人类教师全库签核。

词库质量与来源：`docs/CET4_1500_DATA_REPORT.md`；开发报告：`docs/V1.6_REPORT.md`；修改前备份：`backups/v15_before_v16_20261009_191053/`。

掌握度继续按英语单词关联，原120与新库交集92词共享进度。`SaveData`、存档格式与原词库未修改；音量设置和18件遗物/3种补给保留。当前不支持关闭后继续同一冒险，事件和地图进度保持在当前运行内；关闭前的长期学习进度仍保存。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode data
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode unit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode regression
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode capture -Resolution 1280x720
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode capture -Resolution 1920x1080
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode record
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v16.ps1 -Mode audit
```

测试使用 `.local_test/v16_profile/` 的独立存档，截图与结果在 `.local_test/v16/`。旧回归使用原规则夹具，新测试单独覆盖三档十二层路线、事件与蓄势。游戏本身无Python或联网依赖；Python只用于开发期词库整理和质量校验。

## V1.5 历史玩法

- **十二层探索、34 个节点**：由下向上滚动的图标地图，点线连接可选路径。每局改变节点排列与相邻连接；金色可进入、绿色已完成，已完成节点不能重复领取。使用滚轮、滚动条、查看塔顶和定位当前位置浏览全塔。
- 普通战斗、精英战斗、回忆书房之外，加入 **休息书桌**（恢复最大生命的 20%）和 **藏宝书架**（直接三选一）。首战与第十二层首领必经，中间按连接选择，每层走一个节点。
- **18 件本局遗物 + 3 种可重复补给**：原六件强化保留，新增法力、飞弹、护盾反伤、错词爆发、连击与续航组合。奖励卡显示类别与效果，地图右侧可查看当前遗物。普通胜利一次选择、精英胜利两次；每次至少提供两个未拥有遗物（池子足够时），第三项有机会为补给。
- 为较长旅程增加基础胜利恢复：普通战 5 生命、精英战 8 生命，与治愈羽笔叠加且不超过上限。敌人生命按所在层增加 `(层数 - 1) × 14`，原攻击力、九种攻击、三法术与弱词机制保留。
- **ESC → 声音设置**：背景音乐与战斗/界面音效分别调整，0% 静音，即时生效且自动保存。恢复默认、试听界面音效、返回暂停菜单均可用。设置期间保持暂停，返回冒险不会重新播放整首音乐。

目标单局为 **15～20 分钟**，实际时长取决于阅读速度、正确率、路线和强化组合；目前未经过人工计时验证。标题、战斗、奖励、书房、地图、结算与设置均使用中文；英语单词和音标保留。

### 新强化与组合

| 方向 | 遗物 |
| --- | --- |
| 法力 | 聚能指环：上限 +1；法力泉瓶：每场初始法力 2 |
| 进攻 | 余响铭文：飞弹额外 +3；专注透镜：3 连击起正常伤害 +2；战前筹谋：每场首次答对正常伤害 +6 |
| 防御 | 符文护页：守护获得 10 护盾、上限 20；青金壁垒：每场初始护盾 6；反击墨镜：护盾吸收伤害且存活时反伤 4 |
| 记忆 | 共鸣书签：旧错词爆发加伤 5→10；温习手稿：书房答对恢复 5→7 |
| 续航 | 生命书签：最大生命 +15、立即恢复 15；复苏墨水：每场首次 5 连击恢复 8 |
| 补给 | 生命药剂：立即恢复 20；应急护符：下场起始护盾 +8；灵感墨滴：下场首次答对正常伤害 +8（可累积到 16） |

例如，法力泉瓶 + 聚能指环支持频繁爆发；符文护页 + 青金壁垒 + 反击墨镜偏向防御；词锋之刃 + 专注透镜 + 连击之焰偏向连续进攻。每局随机三选一，不能保证拿到完整组合。

学习仍使用原 `user://wordrogue_save.json`，音量单独保存到 `user://wordrogue_audio.cfg`。重开只清除本局遗物、补给与临时资源，不清除长期掌握度。未更改词库、学习算法、存档格式、角色 PNG 或 BGM 文件。

V1.5 报告：`docs/V1.5_REPORT.md`。修改前工程备份：`backups/v14_before_v15_20261009_171328/`。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode import
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode unit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode regression
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode av
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode capture -Resolution 1280x720
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode capture -Resolution 1920x1080
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode record
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v15.ps1 -Mode audit
```

测试在 `.local_test/v15_profile/` 使用独立存档，结果与实机画面在 `.local_test/v15/`。旧测试通过内部兼容夹具使用原四层路线，正式游戏始终使用十二层地图。

## V1.4 历史玩法

开始冒险先进入路线地图：必经普通战 → 普通战/回忆书房 → 精英/普通战 → 最终首领。金色节点可进入，完成、跳过和未解锁各有状态；只允许连接的节点，已完成节点不可重访。生命与强化在旅程中继承，每场战斗重置法力 1、护盾 0 和连击。

回忆书房复习三个不同的本局错词/低掌握度词：答对恢复 5 生命，答错无伤害，按原规则更新学习数据；不触发攻击、连击或法力收益。书房计入学习报告，另有战斗答题与书房复习计数。普通胜利领取一次三选一，精英胜利连续领取两次合法三选一，再返回地图；首领胜利直接结算。

右上方提前显示怪物下一步和实际预计伤害，选择法术可预览防御收益，提交后预告保持不变。答对打断攻击；答错执行预告。普通怪拥有墨弹/暗影扑击，精英拥有纸刃/墨蚀批注/撕页重击，首领拥有古书冲击/遗忘烙印/知识审判/封印书页。强力攻击不连续出现。

墨蚀只影响下一题：答错额外 +3，答对清除。封印命中扣 1 法力，最低 0。完全免疫或护盾挡住的攻击不附加墨蚀/封印。首领存活生命第一次降至 50% 时进入第二阶段，增加审判和封印权重，不回血或提高原始攻击。

守护咒文保留 **100% 正常伤害 +8 护盾**；新增答错时本次攻击减伤 30%，仍消耗法力且不获得护盾。伤害按倍率、墨蚀、法术减伤、学者免疫、护盾、生命顺序处理，整数向上取整。

当前报告：`docs/V1.4_REPORT.md`；开发前备份：`backups/v13_before_v14_20261009_144914/`。词库、学习算法、存档格式、六种强化、正式图片和 BGM 保留。

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode unit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode regression
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode av
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode capture -Resolution 1280x720
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode capture -Resolution 1920x1080
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode record
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v14.ps1 -Mode audit
```

上述命令均隔离至 `.local_test/v14_profile/`，不修改真实学习存档。截图、测试记录和带声音的实际引擎演示保存在 `.local_test/v14/`。录像通过脚本选择既有合法攻击以完整演示九种演出，不是人工通关录像。

以下为历史版本实现记录；V1.1～V1.3 的固定路线已由 V1.4 地图替代。

## 启动

使用现有 **Godot 4.7.2** 打开 `project.godot`，按 F5。也可在 PowerShell 执行：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64.exe' --path 'D:\项目\1'
```

设计分辨率 1920×1080，默认窗口 1280×720。16:9 等比缩放，其他比例保留边缘留白。

## V1.1 已实现

- 保留 V1 的 120 词、四场路线、六件强化及原有战斗和 Mastery 规则。
- 魔法学徒与敌人的程序绘制角色、图书馆背景、Container 战斗布局。
- 正确：卡片发光、施法、青蓝投射物、命中、飘字与 HP 动画；错误：紫红反击，正确释义保留约 1.8 秒。
- 轻微待机浮动、分级 Combo、精英/Boss 入场、死亡渐隐与胜败反馈。
- Boss 优先本局真实错词，再考察低 Mastery；排除最近三题。弱词和本局错词的标识分别依据实际数据。
- ESC 原生暂停：继续、重开、返回标题、退出。离开或重开均需确认，暂停停止作答、延时和 Tween。
- 冒险日志明确区分 Questions Answered、Unique Words、Correct、Wrong、Accuracy、Best Combo。
- 可选 PNG 与十二种音效事件入口，缺失时使用程序绘制回退或静默跳过。

## V1.2 最终视听整合

已接入用户提供的玩家、Ink Wraith、Marginalia、Librarian 和魔法图书馆背景。两场普通战共用 Ink Wraith 立绘，保留各自既有名称和属性。角色保持宽高比；Boss 单独分配更宽的显示栏和垂直空间，不遮挡答案。正式背景使用 Cover 和可调 30% 深蓝遮罩，缺图仍可回退。

玩家蓝金光迹/星芒、敌人紫墨碎片、Boss 深红书页环复用原有作答动画状态。没有修改 120 词、学习算法、属性、强化或四场流程。

十二个 CC0 短音效和两首循环 BGM 已实际下载、处理并导入。普通/精英共用音乐，Boss 切换专用音乐；奖励降低音量、标题/报告停止音乐、ESC 冻结音乐；换题不重播。沿用 `AudioBus.play_event()` 接口，音量参数在 `scripts/audio_bus.gd`，无额外设置页面。来源、作者与许可证见 `docs/ASSET_CREDITS.md`。

V1.1 修改前备份：`backups/v11_before_v12_stage1/`。立绘专项测试：在隔离测试存档环境下运行 `--script res://tests/artwork.gd`，使用图形模式时会保存 `.local_test/artwork/` 渲染截图。详细结果见 `docs/V1.2_STAGE1_REPORT.md`。

本轮可恢复备份：`backups/v12_stage1_before_final_20261009/`，未覆盖旧备份。最终报告见 `docs/V1.2_FINAL_REPORT.md`；实际普通/精英/Boss 截图在 `.local_test/v12_final/`，1920×1080 版本在该目录的 `1920x1080/` 下。

## V1.3 多法术战斗

每题先在紧凑技能栏选择法术，再回答四选一。新题默认奥术飞弹，选中技能金框强调；法力不足禁用。切换不消耗资源，提交答案时才扣除法力，无论答对或答错。

| 法术 | 消耗 | 答对效果 |
|---|---|---|
| 奥术飞弹 | 0 | 原正常伤害；法力 +1，最多 3 |
| 守护咒文 | 1 | 原正常伤害；护盾 +8，最多 16 |
| 记忆爆发 | 2 | 原正常伤害 ×180%；单词本局之前答错过时额外 +5 |

每场起始法力 1、护盾 0。答错仍反击，护盾先吸收伤害；Scholar Shield 免疫优先于护盾消耗。先按既有 Combo、Word Blade、Tome、Flame 算出正常最终伤害，再应用一次法术倍率，整数伤害向上取整。Crystal、Quill、Mastery 和报告沿用旧规则。记忆追加效果只依据本局错词，不依据长期错题总数。

奥术：小型蓝金光弹；守护：金蓝旋转符文屏障与较小飞弹；记忆：短蓄力、放大的星芒投射物与命中爆发。本局错词触发 `记忆共鸣 +5`。敌人用紫墨弹，首领用深红变体。ESC 冻结全部法术演出，切屏取消延时和 Tween，回收特效。

试玩修正：守护咒文的伤害由 50% 改为 100%，仍消耗 1 法力、获得 8 护盾。标题、技能、角色/敌人、奖励、暂停菜单、战斗反馈和学习报告均已中文化；题目英语单词、音标、WordRogue 品牌和 ESC 按键名保留。当前修正报告见 `docs/V1.3_FIX_REPORT.md`。

攻击/命中音效绑定已修复：敌人不再共用降低音调的玩家施法声，碰撞和怪物受伤分别播放；守护启动、挡伤、记忆蓄力/释放/爆发各有事件。新增 9 个 CC0 短音效，原文件和 BGM 保留。来源见 `docs/ASSET_CREDITS.md`。声音事件在实际释放、命中时各触发一次，主观听感需试玩验收。

V1.2 完整可恢复备份：`backups/v12_before_v13_20261009/`。本轮未创建新的游戏工程，也未安装软件。交付报告：`docs/V1.3_REPORT.md`。

## 数据与备份

原词库未修改。学习数据仍保存在 `user://wordrogue_save.json`，存档格式兼容 V1。`config/name` 保留原值以继续使用原存档目录。重开、返回标题不重置长期 Mastery。

开发前的 V1 备份在 `backups/v1_20261008/`。恢复时先保存现有工程，再将备份内的工程文件复制回根目录。该备份不包含或清空用户学习存档。

Questions Answered = 本局 Correct + Wrong；Unique Words = 本局已结算题目中的不同词数；Accuracy = Correct / Questions Answered。报告不读取全局累计答题数。

## 工程职责

- `scripts/main.gd`：战斗状态、演出、流程、入场与报告；切屏时取消 Tween，通过屏幕版本号阻止旧延时回调。
- `scripts/ui/screen_base.gd`：沿用 V1 的基础 UI、标题与奖励页面。
- `scripts/ui/battle_view.gd`：Container 战斗布局。
- `scripts/ui/actor_view.gd`、`actor_art.gd`：PNG 接入、等比缩放与程序角色回退；待机和攻击位移分别管理。
- `scripts/ui/magic_bolt.gd`、`library_backdrop.gd`：程序投射物与背景。
- `scripts/ui/spell_effect.gd`：程序护盾符文及记忆蓄力；`magic_burst.gd`：命中爆发。
- `scripts/ui/pause_menu.gd`：始终运行的 ESC 菜单、二次确认和音量设置。
- `scripts/route_state.gd`、`scripts/ui/route_view.gd`、`map_icon.gd`：十二层随机节点与连接、滚动地图、原生图标绘制。
- `scripts/reward_catalog.gd`、`scripts/ui/reward_badge.gd`：新增遗物/补给数据与分类图标；效果仍由 GameState 统一结算。
- `scripts/game_state.gd`、`word_bank.gd`、`save_data.gd`：既有战斗、学习、出题和存档逻辑。
- `scripts/audio_bus.gd`：可选本地音效、BGM 播放、独立音量和设置保存。

图片与音效路径和替换方法见 `assets/README.md`。没有下载替代角色或背景；外部音频全部选用许可证清晰的 CC0 来源。

## 测试

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_smoke.ps1
```

该命令把测试数据隔离到 `.local_test/automated/`；`smoke.gd` 也会检查隔离路径，防止重置真实档案。测试覆盖完整路线、死亡、重复作答、暂停、动画中重开与返回标题、全部强化、统计、Boss 针对样例、Mastery 边界和存档重读。

最终专项测试（同样自动隔离存档）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v12.ps1 -Mode av
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v12.ps1 -Mode capture -Resolution 1280x720
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v12.ps1 -Mode capture -Resolution 1920x1080
```

新增音效/图片后先让 Godot 导入。游戏本身不依赖开发用的下载与处理脚本，不需要网络。

V1.3 专项命令（均隔离到 `.local_test/v13_profile/`，不写真实学习存档）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode import
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode unit
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode smoke
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode av
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode capture -Resolution 1280x720
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode capture -Resolution 1920x1080
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode record
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\run_v13.ps1 -Mode audit
```

当前中文界面的三法术、护盾吸收、标题/暂停/奖励/报告与精英/首领实际截图保存于 `.local_test/v13_cn/`，另有 `1920x1080/`。`record` 用 Godot 内置 Movie Writer 保存带声音的 `spells_demo.ogv`；这是脚本驱动的真实引擎演示，不是人工通关录像。为了稳定展示记忆加伤，演示脚本重新呈现该局已实际答错的词；正式首领抽词算法保持不变。修正前的截图与录像仍在 `.local_test/v13/`。

## 当前限制与人工检查

已通过 Godot 图形运行检查立绘、背景、施法、反击与实际音效混音。自动测试能验证音频加载、播放与切换，但听感和长时间连续答题的疲劳程度仍需人工试玩。图片作者/许可未随用户文件提供，本轮保持素材像素不变并记录为用户提供。

请优先检查 1280×720 与 1920×1080 的按钮及角色、答对/答错投射物、动画中 ESC 暂停恢复、三连/五连/八连、奖励高亮、精英与 Boss 的真实错词提示，以及胜败报告数字。

V1.5 请额外检查地图滚动、不同路线的收益、遗物组合、长局节奏，以及音量调整和重启后的保存。

## 独立试玩包与 Android 发布准备（2026-10-11）

Windows 64 位 Release 位于 `releases/windows/`，双击 WordRogue.exe；完整压缩包 `releases/WordRogue-Windows.zip` 约 48.81 MiB，游戏 PCK 约 13.51 MiB。保留历史开发文件，发布包排除备份、截图、录像、参考图与用户存档。

新增合法中文/音标字体、横屏触屏提示、返回键与后台暂停准备。Android 暂未导出：缺少 JDK17、SDK、匹配模板和发布签名；Windows 包不能上传为安卓 APK。

完整记录见 `docs/RELEASE_REPORT.md`，Android 所需环境见 `docs/ANDROID_RELEASE_READINESS.md`，玩家运行说明见 `docs/RELEASE_PLAY_README.md`。下一次新构建可运行 `tools/build_release.ps1`，它会自动创建新的独立发布工程；不覆盖原图或存档。正式分发仍需按目标商店验证，未承诺整体 5MB。

## Android 试玩包与 TapTap 检查（2026-10-12）

已生成 `releases/android/WordRogue-v1.9-android-arm64-preview.apk`，约38.23MiB，Android7+/ARM64；使用独立签名，16KB对齐和资源检查通过。原始工程源码/美术/学习存档保持不变，安卓配置只应用于独立构建副本。

本机未连接安卓手机，真机安装与手机操作待确认。目前仍缺实名认证/防沉迷和隐私/平台材料，不能将可签名APK等同于已通过TapTap下载审核。用户已选无版号免费试玩，账号已认证、游戏未创建。

报告：`docs/TAPTAP_READINESS_REPORT.md`；创建填写建议：`docs/TAPTAP_SUBMISSION_DRAFT.md`；玩家安装说明：`releases/android/ANDROID_PLAY_README.md`。

## 战斗古籍 UI（2026-10-22）

**2026-10-23更新：**古籍风格已扩展到标题、难度、地图、奖励、事件、回忆/休息、暂停/声音设置及胜败日志。开发分支 `ui/whole-grimoire-20261023`；打开当前 `project.godot` 运行，历史发行包保持原样。见[全流程界面报告](docs/WHOLE_GAME_UI_REPORT_20261023.md)和[截图对照](docs/ui-comparison.md)。

战斗页使用独立羊皮纸单词面板、卷轴答案、三法术徽记、旧金状态框和地面符文；保留原战斗与长期学习数据。源工程在 `ui/battle-grimoire-20261022` 分支，改造前备份在 `backups/battle_grimoire_20261022/`。

用 Godot 4.7.2 打开当前 `project.godot` 运行即可查看；既有 `releases/` 试玩包未覆盖。完整说明和两种分辨率前后截图见 [战斗 UI 交付报告](docs/BATTLE_GRIMOIRE_UI_REPORT_20261022.md)。
