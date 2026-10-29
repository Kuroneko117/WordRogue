# 《遗忘书塔》战斗古籍 UI 改造报告

日期：2026-10-22。工程：`D:\项目\1`。实际引擎：**Godot 4.7.2.stable.official.ed1daf0bf**，GDScript / Compatibility / Windows。

## 1. 范围与工程保护

本轮完成战斗页面的原生交互 UI、材质与站位改造。入口仍为 `scenes/main.tscn → scripts/main.gd → BattleView`，没有创建一套替代战斗系统。

- 开始时原目录没有 Git 仓库，因此先保存已有工程，再建立本地基线提交 **1756b0f**。
- 基线分支：`baseline/before-battle-ui-20261022`。
- 实施分支：**`ui/battle-grimoire-20261022`**。
- 备份：`backups/battle_grimoire_20261022/`，包含脚本、场景、素材、词库、配置、测试、工具、文档、真实用户目录只读副本、参考图和资源哈希清单。缓存、历史发行包和旧备份保留在原位置，没有复制成新的运行版本。
- 对原有 `assets/`、`data/` 和关键核心脚本逐项 SHA256 对比：**0 项变化**。新增 UI 放在独立目录。
- 真实 `wordrogue_save.json`、`wordrogue_audio.cfg` 与备份哈希一致。测试的学习写入及音量操作使用 `.local_test/` 下独立用户目录。编辑器和工具运行会更新引擎日志，不代表长期存档被修改。
- 没有覆盖 `releases/` 下的 Windows/Android/Web 发行包，也没有推送或发布到外部平台。

## 2. 审计与视觉方向

已读取 `project.godot`、主场景、战斗控制器、BattleView、ActorView/ActorArt、MomentumView、公共 UI Theme、输入适配、展示配置及既有视觉规范。检查目标参考图并实际运行改造前界面。

新页面采用：深靛蓝底、旧金切角金属框、暖象牙羊皮纸、青蓝玩家法术、紫色记忆法术与敌方威胁色。保留既有主角、全部敌人 PNG 和各战斗背景。

| 区域 | 实际实现 |
| --- | --- |
| 顶部 | 楼层/遭遇标题、难度铭牌、ESC 暂停按钮；替代重叠的全局水印 |
| 左上 | 玩家名、连击、红色生命条、法力/护盾与异常状态；旧金装饰框 |
| 右上 | 敌人名/类型、生命条、原有分段蓄势条与不可打断提示；攻击意图移动至此 |
| 单词区 | 独立羊皮纸材质，词性、英文衬线单词、音标保持动态；弱词沿用真实数据提示 |
| 法术槽 | 奥术金、守护蓝、记忆紫三套徽记与边框；按键、消耗、效果、选中/缺法力/锁定反馈 |
| 答案区 | 两列四个卷轴按钮，原生动态中文；独立 A/B/C/D 菱形字母牌，六态显示 |
| 左右角色 | 保持原比例，扩大完整立绘显示；统一地面基准，增加旧金法阵、蓝/紫阵营光与柔光 |
| 底部 | 攻击、已答题数量、反击/不可打断提示；意图详情不再占用底部大面板 |

布局由 MarginContainer、VBox/HBox/GridContainer 管理，沿用项目 1920×1080 参考画布和 canvas_items 缩放。立绘继续使用 `visual → pose → art`，Idle/Attack/Hit/Death 的原有引用和施法原点均保留。

## 3. Figma 与 ComfyUI 实际结果

### Figma

已成功通过当前连接创建并写入 [WordRogue · Battle Grimoire UI](https://www.figma.com/design/3PW9KHOUqll0VIuNiSNWej)。

- 9 个颜色变量；答案六态组件和三法术三态组件，合计15个变体。
- 评审实例与组件源分开，修复初次排列重叠，并截图复核。
- 这份 Figma 文件是**配色和交互状态规范**，采用无纹理的组件示意；不是完成的手绘界面稿。最终视觉以本报告 Godot 实机截图为准。

### ComfyUI

发现本机 `127.0.0.1:8188`，检查服务节点、模型目录、外部模型路径与三个工作流：`H3-I2V-480p`、`H3-T2V-480p`、`H3-TURBO-480p`。部署内容为 MiniMax H3 视频模型、文本编码器、视频/音频 VAE 与 Turbo LoRA，没有发现适合此次静态 UI 制作的现成图像工作流。

没有把视频模型当作图片模型执行，也没有安装/下载新模型。两张空白纸张使用内置图像生成工具，其余装饰采用本轮编写的 SVG。

## 4. 新增素材

目录：`assets/ui/grimoire/`。**11个独立图像文件，源文件合计975,413字节，约0.93MiB**；另外有来源说明与 manifest。PNG均验证有效透明通道。

| 素材 | 用途 / 来源 |
| --- | --- |
| `parchment_scroll.png` | 1024×321 单词羊皮纸，内置生成工具单独生成，无文字 |
| `answer_scroll.png` | 1024×320 答案宽纸面卷轴，单独生成，无文字 |
| `arcane_seal.svg` | 原创奥术飞弹徽记 |
| `aegis_seal.svg` | 原创守护盾徽记 |
| `memory_seal.svg` | 原创记忆星阵徽记 |
| `gothic_frame.svg` | 原创旧金切角状态/信息框 |
| `spell_arcane_frame.svg` | 金色法术槽边框 |
| `spell_aegis_frame.svg` | 青蓝法术槽边框 |
| `spell_memory_frame.svg` | 紫色法术槽边框 |
| `ribbon_frame.svg` | 原创尖端铭文横幅，用于反馈文字 |
| `rune_circle.svg` | 原创透明法阵；配合引擎原生柔光 |

所有文字由 Godot 渲染。答案的悬停、按压、锁定、正确、错误通过同一纸张的 StyleBoxTexture 及运行时色调实现，未将生成图中的文字当作正式文本。来源与哈希详见 `assets/ui/grimoire/manifest.json`、`ART_NOTES.md`。

## 5. 修改文件与职责

### 运行时代码

- `scripts/ui/battle_view.gd`：战斗容器构图、立绘尺寸/位置、状态面板、意图位置、法术槽和答案外观入口。
- `scripts/ui/battle_theme.gd`（新增）：战斗专用九宫格样式、纹理缓存、六态答案与三法术配色、缺图样式回退。
- `scripts/ui/battle_button.gd`（新增）：原生 Button 子类；徽记/字母牌、聚焦/悬停/按压短 Tween。保留 pressed、键盘导航和原始回调。
- `scripts/ui/battle_stage_light.gd`（新增）：不接收鼠标的法阵/地面柔光层；不改 pose 动画或伤害。
- `scripts/main.gd`：仅把单词和答案的外观更新交给 BattleView。结算、状态机、输入、音频、伤害及学习调用不变。
- `.gitignore`：排除发行包、设定参考图与本地代理目录，避免混入本轮 UI 提交。

`project.godot`、`.tscn`、GameState、WordBank、SaveData、EnemyBrain/Definitions、MomentumController、AudioBus、难度、地图、事件、奖励等核心文件没有修改。

### 作者工具、测试与记录

- `tools/normalize_grimoire_asset.gd`：仅供作者显式规范化新纸张尺寸，保持比例。
- `tests/battle_grimoire_capture.gd`、`run_battle_grimoire.ps1`：隔离存档的实机截图、布局、长文本、蓄势与缺图回退检查。
- `tests/battle_grimoire_input.gd`：实际鼠标点击、双击锁定、聚焦、暂停与守护恢复检查。
- `tests/grimoire_asset_probe.gd`：验证尺寸/Alpha，输出诊断图到测试目录。
- 本报告、`docs/battle_grimoire_review/` 中交付截图、素材 manifest/说明，以及 README 入口说明。

## 6. 实机视觉检查与修正

所有下图为实际 Godot 窗口渲染结果，不是合成 UI 稿。

### 第一轮试点

运行后发现：原图九宫格切分与透明留白造成纸面被压窄、词性/音标落在纸面外；临时纹理引用释放使图标/法阵成为白块；法术长文换行挤压。

修正：纸张按比例规范化；纸面内容安全边距；纹理缓存；法术使用稳定三行结构。

### 第二轮检查及定向收敛

再次截图发现：单词纸张正常，但同一张华丽面板用于答案时仍显窄，遂生成独立宽纸面答案卷轴，为答案单独配置区域取样/九宫格；三法术改为独立色系边框，提示区改为尖端横幅。图标、题目与答案恢复可读。

补充检查：长中文选项和正确释义可换行；首领二阶段名字、精英和满蓄势均不与立绘相交；法阵旧金与阵营色分别绘制，修正黄铜乘蓝色出现的绿色偏色；弱词纸张保持暖纸色。边缘复核又发现底部金框受到中文回退字库偏高行高影响，给英文单词单独指定 Latin 字体并收紧间距，同时将 PanelContainer 边界纳入检查，最终金框完整留在安全区域内。最后刷新相关截图，未重复平衡模拟。

### 交付截图

| 画面 | 文件 |
| --- | --- |
| 改造前 1280×720 | [before](battle_grimoire_review/before_1280x720.png) |
| 改造后 1280×720 | [after 720p](battle_grimoire_review/after_1280x720.png) |
| 改造后 1920×1080 | [after 1080p](battle_grimoire_review/after_1920x1080.png) |
| 守护选中 + 满蓄势 | [charge](battle_grimoire_review/charge_guard_1280x720.png) |
| 长文本 + 首领二阶段 | [long text](battle_grimoire_review/long_text_boss_1280x720.png) |
| 答错/正确答案双色反馈 | [wrong answer](battle_grimoire_review/wrong_answer_1280x720.png) |
| Figma组件规范 | [component contract](battle_grimoire_review/figma_components.png) |

前后截图采用真实题目和敌人测试夹具，不是相同一帧的像素对照。全部候选与最终截图、动画中间帧和日志仍位于 `.local_test/battle_grimoire/`、`.local_test/ui_pass/`。

## 7. 实际测试结果

引擎：本机 Godot 4.7.2；图形检查使用真实 OpenGL Compatibility 渲染器 / RTX 4070 SUPER。各测试运行于独立 APPDATA/LOCALAPPDATA，不操作真实学习记录。

| 命令 / 检查 | 实际结果 |
| --- | --- |
| 改造前 `--resolution 1280x720 --script res://tests/ui_layout_probe.gd` | 启动并生成改造前战斗截图 |
| 改造前 `--headless --script res://tests/v19_models.gd` | PASS，0失败；既有词汇/路线/模型基线 |
| `--headless --editor --import` | 导入 PNG/SVG，修复一次 Skin 与原生类重名；后续导入无 Parser Error |
| `tests/run_battle_grimoire.ps1 -Pilot` | 351项，0失败，4张两分辨率试点截图 |
| `tests/run_battle_grimoire.ps1` 最终版 | **1250项，0失败**，14张截图；普通/精英/首领、蓄满、长文本、面板边界、缺图回退 |
| `tests/run_ui_pass.ps1` | **1624项，0失败**；原有完整流程回归，仅执行一次完整回归 |
| 隔离目录 `--script res://tests/battle_grimoire_input.gd` | **14项，0失败**；两种分辨率的原生鼠标/聚焦/双击/暂停及守护效果 |
| `--headless --script res://tests/grimoire_asset_probe.gd` | 两张 PNG、徽记与法阵均有有效 Alpha，透明角正常 |
| 保护清单 SHA256 对比 | 原有素材/数据/关键核心脚本0变化；真实学习存档和音量配置一致 |

原有完整回归覆盖：标题/地图/战斗入口、Q/W/E 与数字作答、正确/错误单次结算、三法术施放和命中音效顺序、Combo、HP/护盾、八种现有敌人立绘、暂停/ESC/音量独立静音与设置保存、缺图和背景回退、音乐不叠播、死亡报告、再开新局、原生七层路线通关与首领二阶段。没有修改或重测大量平衡组合。

完整回归后只调整了法阵色、英文行高和垂直间距，最终又使用强化后的1250项专项检查刷新截图，没有再次重跑整条路线。

测试夹具个别施法截图将敌人HP提高到1000以避免提前死亡，这是测试隔离数据；本报告正式交付主图使用正常敌人数值。测试通过并不等于已逐帧人工确认全部26种攻击动画的审美质量。

## 8. 与参考图的差异及人工验收

### 已知视觉差异

1. 参考图是整体绘制的概念界面，本实现是可交互且可缩放的独立素材组合；框饰目前以精细矢量刻线为主，没有复刻概念图中所有立体雕花、挂链、羽笔和散页。
2. 法术徽记为原创 SVG，材质和笔触比参考图更规整；后续可在保留现有交互组件的前提下替换成手绘徽章。
3. 使用既有正式场景背景及其照明，未重绘参考图的整座哥特大厅；角色保留原图内部光影，新增的是脚下光与法阵，没有做全身动态重打光。
4. 720p 法术槽采用三行紧凑排版，优先保证中文、消耗与状态完整；与参考图两行宽槽不同。更极端的宽高比不在本轮验收范围。
5. 本轮完成源工程，既有发行 EXE/APK/Web 包保持原版本，启动老包不会看到本次界面。

### 建议人工只检查这些

- 从当前 `project.godot` 启动，进一场普通战；观察纸面和中文在自己的显示器上是否舒适。
- 用鼠标和 Q/W/E 切换三个法术，检查选中、法力不足、按键导航和说明。
- 答对、故意答错一次，查看原有弹体、伤害、红绿卷轴反馈；ESC中途暂停/恢复。
- 到精英或Boss，观察弱词、满蓄势、不可打断、二阶段长名字以及大型立绘。

下一轮若继续美术精修，应优先给状态框和法术徽记增加与现有立绘匹配的手绘材质，而不是新增玩法或扩大本轮范围。
