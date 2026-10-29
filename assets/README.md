# V1.9 新主角

当前使用characters/word_mage_v2.png（1086×1448 RGBA透明）。源图是设定参考图/星纹秘典的言灵法师.png；仅去除白背景，不覆盖源图。旧word_mage.png保留并作为缺失V2时的正式回退。角色比例、pose动画与三法术保留；归一化施法手原点(0.84,0.205)。

背景和音频沿用下方V1.8记录；本轮没有新增BGM、WAV或背景。细节与人工透明边缘验收见docs/V1.9_INTEGRATION_REPORT.md。

# V1.8 当前资源接入

当前新增BGM：`audio/bgm/title_map.ogg`、`elite_battle.ogg`、`memory_rest.ogg`、`event_special.ogg`；原两首保留。四首均为实际CC0音乐，作者、许可证、源下载及处理记录见 `audio/licenses/V1.8_LICENSES.md` 和 `audio/v18_manifest.json`。

当前背景：`backgrounds/library_corridor.jpg`（用户12.jpg，普通战）、`library_elite.jpg`（13.jpg，精英）、`memory_chamber.jpg`（14.jpg，回忆/休息）。Boss、标题/地图仍使用旧主背景，特殊事件使用旧祭坛；13与旧祭坛字节相同，不能算两个不同画面。全部等比Cover；方形12上下裁43.75%，13裁约1.42%，14横向裁约0.37%。

新音效文件18个，已通过实际事件绑定使用；旧21个WAV原字节保留。`AudioBus.MATERIAL_SOUNDS` 指向新家族片段，`TEXTURE_FALLBACKS` 保留旧音源回退；没有增加声音事件名。

尘页守卫正式资源入口 `enemies/dust_guard.png` 尚无文件，缺失时先回退 `ink_wraith.png`。不要用其他画风图片或设定板替代。

以下为历史接入约定，当前状态以本节和V1.8报告为准。

## V1.7 接入记录

旧资源和下面的历史来源记录均保留。详细分类与四只新怪物美术规范见 `docs/V1.7_STYLE_PLAN.md`。

## 图片

| 路径 | 当前状态 / 用途 |
| --- | --- |
| `backgrounds/library_battle.png` | 现有正式背景；战斗、标题与地图最终图片回退 |
| `backgrounds/memory_rest.jpg` | 已接入用户书房图：回忆书房、休息、书页/抄写员事件、报告 |
| `backgrounds/event_ritual.jpg` | 已接入用户祭坛图：书匣/词典/伏击事件、藏宝奖励 |
| `backgrounds/title_map.png` | 待提供；缺失回退旧图 |
| `backgrounds/library_corridor.png` | 待提供横版；不使用方形参考图强行裁切 |
| `backgrounds/library_elite.png`、`backgrounds/library_boss.png` | 待提供；缺失回退旧图、使用不同遮罩深度 |
| `enemies/paper_golem.png`、`enemies/grimoire_mimic.png` | 第二阶段已接入用户1.png / 2.png；缺失仍显示现有程序角色 |
| `enemies/lantern_wisp.png`、`enemies/silent_archivist.png` | 第二阶段已接入用户3.png / 4.png；缺失仍回退 |

PNG需向左、透明、无边框/文字/说明板。沿用 `ActorView.visual → pose → art`，统一缩放保持宽高比。新怪物画布目标高度依次为420/375/350/450设计单位（720p约280/250/233/300px），最终受列宽限制。旧主角与怪物尺寸不变。

背景使用KEEP_ASPECT_COVERED，书房裁切不足0.4%，祭坛约1.42%；深蓝遮罩默认35%/43%，卡片保护文字。参考图原件没有改动，不把设计总览板当作素材。

## 场景音乐（assets/audio/bgm/）

| 逻辑分类 | 首选文件 | 当前回退 |
| --- | --- | --- |
| title_map | `title_map.ogg` | 静音（尚缺文件） |
| battle_normal | `normal_battle.ogg` | 已有 |
| battle_elite | `elite_battle.ogg` | `normal_battle.ogg` |
| battle_boss | `boss_battle.ogg` | 已有；缺失可回退普通 |
| memory_rest | `memory_rest.ogg` | 标题曲或静音 |
| event_special | `event_special.ogg` | 标题曲或静音 |
| optional_victory | `victory_result.ogg` | 标题曲或静音 |

目前只有原两首音乐；上述待提供曲目不是已制作内容。放入合法授权OGG后用Godot导入并重启游戏，自动按场景选曲。单播放器串行淡出0.2s/淡入0.4s，同曲安静/恢复0.25s，缺曲淡出0.25s。ESC暂停音乐位置与Tween；音量仍按用户设置。

## 怪物音效

真实事件映射在 `scripts/presentation_profiles.gd`（攻击→表现）与 `scripts/audio_bus.gd` 的 `MATERIAL_SOUNDS`（事件→已有源文件/音调）。每个事件先查同名WAV/OGG，再查已备的CC0片段；以后例如放入 `audio/sfx/archive_chain_cast.wav` 与 `chain_hit.wav`，导入并重启即可覆盖对应回退，独立素材以原音调播放。

当前没有下载或制作新音频。新事件用既有挥动、石击、金属、宝石与蓄力片段过渡，不代表已经获得真实纸张、墨水、链条与灵火音色。释放/蓄力与命中各一次，玩家实际扣血才触发受击。事件来源继续见 `docs/ASSET_CREDITS.md`。旧事件接口保留。

---

## 历史资源记录

# Optional original art and sound

V1.2 uses the five supplied character/background PNGs, twelve locally prepared CC0 SFX, and two CC0 music loops. Missing optional resources still fall back to procedural art or silence. Full attribution and source mappings are in `docs/ASSET_CREDITS.md`.

## Images

Place licensed/original files at:

- `characters/word_mage.png` — player, facing right, transparent background.
- `enemies/ink_wraith.png` — both normal battles, facing left; the second battle's V1 name and statistics are retained.
- `enemies/marginalia.png` — elite, facing left.
- `enemies/librarian.png` — Boss, facing left.
- `backgrounds/library_battle.png` — 16:9 library background.

Open the project in Godot so it imports new files, then restart the game. Actor art is fit proportionally inside `ActorView`; `art_scale`, `art_offset`, and standard `modulate` adjust scale, placement, and opacity. The attack `pose` remains separate from idle float, so asset replacement does not require rewriting combat. Backgrounds preserve aspect ratio and crop to cover the viewport.

At 1280×720 the player/elite target about 290px, normal art about 250px, and Boss about 330px, with width limiting for the wide Boss. `texture_height` uses design-space units (720p is two thirds of the 1920×1080 design). Uniform fitting reserves room for animation inside the role columns. Background uses Cover and an adjustable 30% deep-blue shade; it does not add the procedural shelves over the PNG.

## Audio

V1.4 reuses the existing CC0 clips for 17 named enemy attack events. `AudioBus.ATTACK_SOUNDS` maps each event to its source basename and pitch. This separates light bolts, paper swishes, curses, heavy strikes, book casts and seals without downloading extra assets. Impact events have reduced volume, and an attack emits exactly one injury event only when HP is actually lost. Existing music files and BGM flow are retained. Detailed mappings are in `docs/ASSET_CREDITS.md` and `docs/V1.4_REPORT.md`.

Place `.ogg` or `.wav` in `audio/sfx/`, named exactly after one of these events:

`ui_click`, `correct`, `wrong`, `player_cast`, `player_hit`, `enemy_hit`, `enemy_death`, `combo_trigger`, `reward_select`, `victory`, `defeat`, `boss_intro`.

`AudioBus.play_event(event)` preserves the original event API. In V1.3, aliases map `player_cast → arcane_release`, `enemy_hit → enemy_hurt`, `player_hit → player_hurt`, `combo_trigger → combo`, and `magic_hit → projectile_impact`. `enemy_cast` now has its own file and is no longer a pitched player sound. Missing audio is silent. Master/SFX/BGM parameters in `audio_bus.gd` adjust volume without adding a settings screen.

V1.3 also uses `aegis_activate`, `shield_hit`, `memory_charge`, `memory_burst`, and `burst_impact`. Provide matching WAV/OGG files under `audio/sfx/`. Release events occur when a projectile appears, and collision/hurt events when it reaches its target. Charge plays only for a correct Memory Burst. Injury is skipped when no HP is lost; absorbed shield damage has its own event. Old V1.2 files remain available but the old cast/hit bindings are replaced.

Nine new CC0 samples are listed in `docs/ASSET_CREDITS.md`. Preparation parameters and raw-source measurements are in `audio/v13_manifest.json`; decoded output is checked by the V1.3 tests. These files have trimmed leading silence, short fades, and bounded peaks. Master/SFX/BGM levels remain -1/-9/-25 dB; collision, enemy hurt, burst impact and charge have an additional -5 dB so layered sounds stay controlled. Subjective timbre still needs listening during play.

`normal_battle.ogg` persists through normal and elite battles; `boss_battle.ogg` replaces it for the final encounter. Rewards and intros lower music, title/report stop it, ESC pauses it. Changing questions does not restart music. Effects are bounded to eight simultaneous players and release themselves when finished.
