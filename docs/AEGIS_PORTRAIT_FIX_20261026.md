# 守护咒文导致敌人缩小：修复记录

工程 `D:\项目\1`；Godot 4.7.2。基线 `b5e6042`，分支 `fix/aegis-enemy-scale-20261026`，修改前脚本与记录保存在 `backups/aegis_scale_fix_20261026/`。

## 已复现的原因

选择第二技能后，敌人意图 Label 增加“守护答错减伤30%”一行，高度从86变为120，挤占下方立绘容器34像素。墨影与精英的显示区域从482×495缩为482×461，基础缩放从1.019565降至0.945652。首领受宽度限制，缩放未变，但容器同样被挤小。

## 修复

仅调整 `scripts/ui/battle_view.gd`：将玩家守护减伤说明放到已有玩家状态栏，与墨蚀提示一起显示；状态栏保持单行，完整说明可悬停查看。敌人意图继续显示原攻击与伤害预告，不因选择守护额外增加一行。

没有调整人物原图、人物目标大小、技能数值、护盾、动画、怪物行为、词库或存档逻辑。

## 实际验证

隔离 `.local_test/quiet_flow/profile/` 的 APPDATA、LOCALAPPDATA，并设置 `WORDROGUE_TEST_PROFILE=1`，运行：

`Godot_v4.7.2-stable_win64_console.exe --path D:\项目\1 --script res://tests/aegis_portrait_regression.gd --rendering-method gl_compatibility --max-fps 60`

- 修复前回归检查实际失败，捕获了上述容器与缩放变化。
- 最终：48项检查、0失败、4张截图。
- 1280×720与1920×1080下，普通、精英及首领切换守护再切回，容器与基础缩放均保持原值。
- 两次实际守护答对施法均扣除1法力、获得护盾、恢复作答，敌人大小保持；墨蚀与守护提示组合正常。
- 测试按原规则在每题重新选择守护，未改变每题默认回到奥术飞弹的行为。

证据：`.local_test/aegis_portrait/before.log`、`after.log`；截图位于该目录的 `before/` 和 `after/` 分辨率子目录。本次仅运行此问题的针对性验证，无完整路线或平衡模拟。
