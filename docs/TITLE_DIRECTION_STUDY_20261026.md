# 标题页方向试作：降低生成图的装饰堆叠感

日期：2026-10-26。状态：可运行的方向试作，尚未经用户视觉认可，不是全流程美术定稿。

## 为什么改变方法

用户明确不满意先前 battle/settings 生成概念的 AI 感。主要观察是重复星纹、满屏高光、金色雕花和多个焦点互相竞争。继续提高纹理复杂度，不能证明美术质量提高。

本次选择：收敛到墨蓝、纸白、旧铜三种颜色角色；使用真实可交互的排版、留白、书脊细线，以及一个可编辑的书塔/书页小标记。既有背景只在标题页降低饱和与亮度，原图不改写。没有调用图片生成器生成整屏界面。

此方法仍不能保证用户认为“没有 AI 感”。背景本身的绘画特征、字标个性与整体艺术方向，仍需要审查和进一步设计；需要独特插画时，应进行定向绘制和逐项修整。

## 工程保护

- Godot：4.7.2.stable.official.ed1daf0bf，现有版本，无升级。
- 工程：`D:\项目\1`。
- 基线 commit：`1545e21`。
- 独立分支：`ui/title-frontispiece-20261026`。
- 修改前脚本、Git 状态、基线标识与真实存档/音量文件校验记录：`backups/title_frontispiece_20261026/`。
- 原有未提交文件保留；没有修改发布包、词库、玩法或长期存档。

## 已接入的标题页变化

- 现有主入口调用新的 `frontispiece_title.gd`，打开工程启动即可查看。
- 标题页使用现有 `library_corridor.jpg`，保持比例覆盖，原生轻量 shader 降低饱和与亮度，并将画面渐隐到左侧墨色底。
- 去除标题页上重复的星纹、金框、皮革按钮与战斗姿态主角；战斗中的正式立绘完全保留。
- 重新安排中文大标题、英文副标、核心句、三级菜单、存档提示和工作室署名。
- 开始冒险、声音设置、退出确认全部调用原有入口，保留 ESC 与键盘确认。
- 原生菜单使用细箭头与下划线区分焦点/悬停，文字颜色区分按下与禁用状态。
- 只保留一条书脊线；小型书塔/书页 SVG 为本项目明确绘制的可编辑路径，无外部图片和新生成的位图。
- 可选背景或小标记缺失时，仍显示墨色背景与可操作的原生菜单。

本次只调整标题页。难度、设置、地图、战斗等页面保持上一轮状态，暂不将此方向批量推广，因此切到这些页面后仍有视觉风格差异。

## 文件

- `scripts/ui/frontispiece_title.gd`：标题布局、原生菜单、局部背景处理与回退。
- `scripts/ui/journal_screens.gd`：标题页构建转交新组件，其他页面不改。
- `assets/ui/frontispiece/tower_book.svg`：64×80 透明矢量书塔/书页标记。
- `assets/ui/frontispiece/manifest.json`：来源、方法与字体说明。
- `tests/title_frontispiece_review.gd`：仅针对标题页的实际点击/键盘与布局检查，复用原测试辅助方法。

## 测试与证据

使用独立的 `.local_test/title_frontispiece/` APPDATA/LOCALAPPDATA 及 `WORDROGUE_TEST_PROFILE=1`，不使用真实玩家配置。

实际执行：

```powershell
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\项目\1' --editor --headless --import
& 'D:\godot\Godot_v4.7.2-stable_win64_console.exe' --path 'D:\项目\1' --script res://tests/title_frontispiece_review.gd --rendering-method gl_compatibility --max-fps 60
```

以上测试命令运行前必须设置隔离配置变量；不要将它当作真实存档中的测试入口。

- 原生图形运行，RTX 4070 SUPER / OpenGL Compatibility。
- 最终结果：48 项检查、0 失败、2 张截图，无脚本/资源/shader 错误。
- 检查分辨率 1280×720、1920×1080，标题与菜单无裁切。
- 实际发送鼠标与 Enter/ESC 输入，验证进入原难度页、打开与关闭原音量设置、退出前原二次确认。
- 实际构建缺图视图，确认回退保留菜单，不加载不存在的图片。
- 首轮设置断言早于界面响应，测试中加入短暂等待后通过；最终运行日志保留。未为该标题试作重复运行完整平衡/通关模拟。
- 真实 `wordrogue_save.json` 和 `wordrogue_audio.cfg` 最后 SHA256 与修改前一致。

截图：

- 旧标题：`docs/whole_ui_review/title.png`。
- 新标题：`docs/title_frontispiece_review/title_1280x720.png`。
- 新标题：`docs/title_frontispiece_review/title_1920x1080.png`。
- 最终运行日志：`docs/title_frontispiece_review/review.log`。

先检查第一轮实机画面，修正被不透明背景遮住的书脊线；再检查最终实机画面与小标记。独立美术审查记录在 `docs/ui_art_rethink_20261026/title_direction_review.md`。

## 仍待确认的美术问题

1. 新标题更冷、更安静，学院与学习冒险的温暖感有所减弱。
2. 小型标记改善识别，但不能替代完整字标设计与独有世界观插画。
3. 中文标题当前优先使用 Windows 宋体，英文为系统衬线字体；不打包分发系统字体。跨平台可回退现有 Noto Sans SC，但字形和气质可能变化，尚未进行移动设备验收。
4. 当前复用通用底层背景创建流程，再由标题组件遮盖；不影响本次显示，但将来正式整理可消除标题底下被遮挡的旧装饰节点。
5. 本次未宣称全游戏 UI、美术、性能或发布验收完成。
