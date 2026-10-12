# WordRogue 素材来源与许可（V1.2 / V1.3）

本轮获取日期：**2026-10-09**。音频均从下列公开页面的正常下载链接取得。全部选用 **CC0 1.0**，允许复制、修改及重新分发，无强制署名；这里仍保留作者、来源和原文件映射。用户提供的图片不标记为网络下载，也不擅自声明其作者或外部许可。

CC0 许可说明：https://creativecommons.org/publicdomain/zero/1.0/

## 音效

工程目录：`assets/audio/sfx/`。原始 OGG 在 `.local_test/audio_sources/`；Godot 原生解码后裁剪前导静音、限制时长、转为单声道 16-bit WAV，统一 RMS/峰值并添加短淡入淡出。具体处理值在 `assets/audio/audio_manifest.json`。没有从商业游戏提取音频。

| 工程文件 | 素材名称 / 原文件 | 作者 | 来源网址 | 许可证 | 获取日期 | 署名要求 |
|---|---|---|---|---|---|---|
| ui_click.wav | Interface Sounds / click_001.ogg | Kenney | https://kenney.nl/assets/interface-sounds | CC0 1.0 | 2026-10-09 | 无强制要求 |
| correct.wav | Interface Sounds / confirmation_001.ogg | Kenney | https://kenney.nl/assets/interface-sounds | CC0 1.0 | 2026-10-09 | 无强制要求 |
| wrong.wav | Interface Sounds / error_001.ogg | Kenney | https://kenney.nl/assets/interface-sounds | CC0 1.0 | 2026-10-09 | 无强制要求 |
| reward_select.wav | Interface Sounds / confirmation_003.ogg | Kenney | https://kenney.nl/assets/interface-sounds | CC0 1.0 | 2026-10-09 | 无强制要求 |
| player_hurt.wav | RPG Audio / bookPlace1.ogg | Kenney Vleugels | https://kenney.nl/assets/rpg-audio | CC0 1.0 | 2026-10-09 | 无强制要求 |
| player_cast.wav | Magic Spell SFX / magical_3.ogg | JaggedStone | https://opengameart.org/content/magic-spell-sfx | CC0 1.0 | 2026-10-09 | 无强制要求 |
| magic_hit.wav | Magic Spell SFX / magical_5.ogg | JaggedStone | https://opengameart.org/content/magic-spell-sfx | CC0 1.0 | 2026-10-09 | 无强制要求 |
| enemy_death.wav | Magic Spell SFX / magical_6.ogg | JaggedStone | https://opengameart.org/content/magic-spell-sfx | CC0 1.0 | 2026-10-09 | 无强制要求 |
| combo.wav | Magic Spell SFX / magical_1.ogg | JaggedStone | https://opengameart.org/content/magic-spell-sfx | CC0 1.0 | 2026-10-09 | 无强制要求 |
| boss_intro.wav | Magic Spell SFX / magical_4.ogg | JaggedStone | https://opengameart.org/content/magic-spell-sfx | CC0 1.0 | 2026-10-09 | 无强制要求 |
| victory.wav | Music Jingles / jingles_PIZZI00.ogg | Kenney Vleugels | https://kenney.nl/assets/music-jingles | CC0 1.0 | 2026-10-09 | 无强制要求 |
| defeat.wav | Music Jingles / jingles_PIZZI15.ogg | Kenney Vleugels | https://kenney.nl/assets/music-jingles | CC0 1.0 | 2026-10-09 | 无强制要求 |

## V1.3 战斗音效修复

新增资源取得于 **2026-10-09**，两个素材包的发布页面均明确标注 CC0：

- [Swishes Sound Pack](https://opengameart.org/content/swishes-sound-pack)，作者 **artisticdude**。木棒、衣架等真实挥动声音。
- [80 CC0 RPG SFX](https://opengameart.org/content/80-cc0-rpg-sfx)，作者 **rubberduck**。魔法、物件碰撞及生物受伤等短音效。

原始包保留在 `.local_test/v13_audio_sources/`。由 Godot 原生解码、裁去前导静音、截取短段、统一单声道 PCM16、加短淡入淡出并限制峰值；无强制署名，仍保留作者和来源。没有使用 CC-BY/ShareAlike 素材包。

| 工程文件（assets/audio/sfx/） | 原文件 | 作者 / 素材包 | 运行用途 |
|---|---|---|---|
| arcane_release.wav | swish-10.wav | artisticdude / Swishes | 奥术飞弹释放；player_cast 别名 |
| enemy_cast.wav | swish-7.wav | artisticdude / Swishes | 敌人及 Boss 投射物释放 |
| memory_burst.wav | swish-1.wav | artisticdude / Swishes | 记忆爆发释放 |
| projectile_impact.wav | item_stone_02.ogg | rubberduck / RPG | 普通投射物碰撞；magic_hit 别名 |
| enemy_hurt.wav | creature_hurt_02.ogg | rubberduck / RPG | 敌人受击；enemy_hit 别名 |
| aegis_activate.wav | item_gem_01.ogg | rubberduck / RPG | 守护符文展开 |
| shield_hit.wav | metal_03.ogg | rubberduck / RPG | 护盾或 Scholar Shield 挡伤 |
| memory_charge.wav | spell_01.ogg | rubberduck / RPG | 记忆爆发短蓄力 |
| burst_impact.wav | stones_02.ogg | rubberduck / RPG | 记忆爆发强化碰撞 |

以上全部 **CC0 1.0**，获取日期相同，无强制署名。V1.2 的 `player_cast.wav`、`magic_hit.wav` 未被覆盖，保留作可恢复的旧资源，但现有事件已转至上表资源。玩家受击 `player_hurt.wav`、UI 音效、两首 BGM 均保留。声学测量、源文件与处理增益见 `assets/audio/v13_manifest.json`（peak/RMS 是处理前测量，实际导出文件由专项测试解码检查）。

## V1.4 复用说明

本轮没有新增网络下载或外部贴图。怪物特效由程序绘制；扑击残影直接使用用户原有敌人 PNG。新攻击音效复用上表 CC0 文件，在 `AudioBus.ATTACK_SOUNDS` 配置独立事件、音调与碰撞音量：

| 事件 | 既有源文件 | 音调 |
|---|---|---:|
| ink_launch / ink_impact | enemy_cast / projectile_impact | 0.9 / 1.0 |
| shadow_lunge / heavy_impact | memory_burst / burst_impact | 0.7 / 0.85 |
| paper_slash / paper_impact | arcane_release / shield_hit | 1.2 / 1.2 |
| curse_cast / curse_impact | memory_charge / aegis_activate | 0.8 / 0.65 |
| torn_page | enemy_cast | 0.6 |
| tome_cast / tome_impact | aegis_activate / projectile_impact | 0.9 / 0.9 |
| oblivion_cast | memory_charge | 0.6 |
| boss_charge | memory_charge | 0.55 |
| judgment_cast / judgment_impact | memory_burst / burst_impact | 0.75 / 0.65 |
| seal_cast / seal_impact | arcane_release / shield_hit | 0.75 / 0.7 |

所有源文件为 `assets/audio/sfx/` 下 WAV；作者、包名和许可沿用 V1.3 表。只调整播放参数，源音频像素/样本与 BGM 文件未修改。音调差异和事件匹配已通过加载/播放检查，主观听感仍需试玩。

## 循环音乐

两首保持原始 OGG 编码，运行时开启循环并以较低 BGM 音量播放。

| 工程文件 | 素材名称 / 原文件 | 作者 | 来源网址 | 许可证 | 获取日期 | 署名要求 |
|---|---|---|---|---|---|---|
| assets/audio/bgm/normal_battle.ogg | Whispers in the Fog / whispers_in_the_fog.ogg | Ruhinre | https://opengameart.org/content/whispers-in-the-fog | CC0 1.0 | 2026-10-09 | 非强制，作者欢迎署名 |
| assets/audio/bgm/boss_battle.ogg | Dark Place (loop) / dark_place.ogg | SkyleTheFrench | https://opengameart.org/content/dark-place-loop | CC0 1.0 | 2026-10-09 | 非强制，作者欢迎署名 |

## 用户提供的图片

这些图片在本轮开发开始前已经存在。本轮核查日期为 2026-10-09；没有重新生成、替换像素或从网站下载。图片作者和许可未随文件提供，由用户管理项目图片的权利信息。

| 工程文件 | 素材名称 | 来源 | 作者 / 许可证 | 日期 | 署名要求 |
|---|---|---|---|---|---|
| assets/characters/word_mage.png | Word Mage | 用户提供，非网络下载 | 未随文件提供 | 2026-10-09 核查 | 由用户素材许可决定 |
| assets/enemies/ink_wraith.png | Ink Wraith | 用户提供，非网络下载 | 未随文件提供 | 2026-10-09 核查 | 由用户素材许可决定 |
| assets/enemies/marginalia.png | The Marginalia | 用户提供，非网络下载 | 未随文件提供 | 2026-10-09 核查 | 由用户素材许可决定 |
| assets/enemies/librarian.png | The Librarian | 用户提供，非网络下载 | 未随文件提供 | 2026-10-09 核查 | 由用户素材许可决定 |
| assets/backgrounds/library_battle.png | Tower Library Battle Background | 用户提供，非网络下载 | 未随文件提供 | 2026-10-09 核查 | 由用户素材许可决定 |

`assets/enemies/library_battle.png` 是用户已有的额外文件，保留原样，游戏未引用。程序投射物、星芒、书页碎片与回退绘图由本项目代码直接绘制，没有新增外部特效贴图。


## V1.7 用户背景与事件映射

本轮没有从网络获取任何美术或音频，也未修改旧PNG/WAV/OGG。

| 正式接入文件 | 用户原始参考图 | 处理 |
| --- | --- | --- |
| `assets/backgrounds/memory_rest.jpg` | `设定参考图/ChatGPT 图像 2026年10月9日 20_51_45.jpg` | 原字节复制；运行时保持比例Cover、35%深蓝遮罩 |
| `assets/backgrounds/event_ritual.jpg` | `设定参考图/ChatGPT 图像 2026年10月9日 21_18_48.jpg` | 原字节复制；运行时保持比例Cover、43%深蓝遮罩 |

以上为用户提供并确认使用的图片，不擅自声称其作者或外部许可。两张设定/方形参考图未作为运行素材。原件仍在原目录。

新怪物声音事件以 `AudioBus.MATERIAL_SOUNDS` 为当前精确绑定表，源文件均来自上述既有CC0资源：`enemy_cast/arcane_release/memory_burst`（挥动），`projectile_impact/burst_impact`（碰撞），`shield_hit`（金属），`aegis_activate`（宝石），`memory_charge`（蓄力）。改变播放音调形成临时差异，并不伪称新增了素材或专用纸张/灵火录音。将来同名独立文件优先于回退，需在此补录真实来源。

## V1.7 第二阶段正式新怪物立绘

用户提供并明确要求接入的独立透明PNG，2026-10-09接入。没有网络下载，也不擅自声明外部作者或许可。四图均为1086×1448 RGBA，Alpha范围0～255，保留原始字节（SHA256与原件一致），只在游戏中等比缩放。

| 用户原件 | 工程路径 | 怪物 |
| --- | --- | --- |
| `设定参考图/1.png` | `assets/enemies/paper_golem.png` | Paper Golem / 纸页傀儡 |
| `设定参考图/2.png` | `assets/enemies/grimoire_mimic.png` | Grimoire Mimic / 拟态魔典 |
| `设定参考图/3.png` | `assets/enemies/lantern_wisp.png` | Lantern Wisp / 幽灯之灵 |
| `设定参考图/4.png` | `assets/enemies/silent_archivist.png` | Silent Archivist / 沉默档案官 |

## V1.8 实际视听完善（2026-10-10）

新增4首真实BGM，均由发布者明确标示CC0，原OGG字节复制；作者及下载/许可页面已核对并保存。

| 工程文件 | 曲名 | 作者 | 来源 / 许可 |
| --- | --- | --- | --- |
| `audio/bgm/title_map.ogg` | Iremos Forest Theme Loop | beardalaxy | [发布页](https://opengameart.org/content/iremos-forest-theme-loop)，CC0 |
| `audio/bgm/elite_battle.ogg` | Cynic Battle Loop | 原作Alex Smith / The Cynic Project；循环编辑Ferk | [循环版](https://opengameart.org/content/cynic-battle-loop) / [原作](https://opengameart.org/content/battle-theme-a)，均CC0 |
| `audio/bgm/memory_rest.ogg` | Forget Me Not，looped版本 | Kistol | [发布页](https://opengameart.org/content/forget-me-not)，CC0 |
| `audio/bgm/event_special.ogg` | Unsolved Investigation | isaiah658 | [发布页](https://opengameart.org/content/unsolved-investigation)，CC0 |

路径以上均相对 `assets/`。详细源URL、SHA256、时长、资源增益见 `assets/audio/v18_manifest.json`。无需强制署名，项目仍保留作者；原normal/boss音乐与21个旧WAV不改。

18个新派生WAV来自前述Kenney RPG Audio与rubberduck 80 CC0 RPG SFX中实际翻书、书本碰撞、黏液、怪物、火焰、锁链和法术片段。每个输出的源列表、作者、许可与混合/裁剪参数见 `assets/audio/licenses/V1.8_LICENSES.md`，没有把重复事件名称当作新素材。

三张新增路径图片来自用户明确确认的 `设定参考图/12.jpg`、`13.jpg`、`14.jpg`，分别复制为 `library_corridor.jpg`、`library_elite.jpg`、`memory_chamber.jpg`。字节与原件一致，运行时等比Cover和深蓝遮罩。13与原event_ritual相同，新增的是精英用途，不声明新原创画面。用户图片不标记为CC0，原件、旧立绘和背景保留。
