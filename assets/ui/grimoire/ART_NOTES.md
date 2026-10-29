# 战斗古籍 UI 素材

## 2026-10-23 全流程扩展

新增 `leather_cover.png`：内置图像生成工具生成单个空白深蓝皮革古籍表面，金色黄铜角饰、极暗低对比皮革中央，无文字/按钮/角色/场景。按比例规范化为1024宽；原稿留在 `backups/whole_ui_20261023/leather_cover_master.png`。材质只用在可容纳雕花的页面，较窄HUD/事件说明使用克制金属框。

生成约束：正交平视的单独横向古籍封面；中央85%无内容，旧金雕花只在外缘，深靛#0b1421；禁止文字、水印与整体UI布局。使用 `StyleBoxTexture`，图中文字均来自原生控件。设置滑块的菱形SVG源保留在 `scripts/ui/flow_folio.gd`，章节/封印源在 `journal_vignette.gd`，不下载外站素材。

日期：2026-10-22。完整来源、字节数和 SHA256 见 `manifest.json`。

## 来源

- `parchment_scroll.png`：本轮通过内置图像生成工具生成的独立空白古纸面板，1024×321，RGBA。
- `answer_scroll.png`：同工具单独生成的空白答案卷轴，1024×320，RGBA。不是从参考图扣取的按钮。
- 其余九个 SVG：本轮为 WordRogue 编写的可编辑矢量装饰，无外部下载依赖。
- `battle_ui_target.png` 仅用于观察风格和构图，未成为游戏运行时资源。
- 两张生成原稿保留在 `backups/battle_grimoire_20261022/generated_*_master.png`；工作图只进行保持比例的尺寸规范化。答案样式使用区域取样去掉透明留白，不剪切文字或设定板。
- 本机 ComfyUI 的三套已部署流程为 MiniMax H3 视频流程；本轮未执行、改装或下载模型。

## 生成规格摘要

### 羊皮纸面板

单个横向空白羊皮纸 UI 元素，透明背景，暖象牙纸色、旧金黄铜边饰、非常淡的角部炼金刻纹；中央80%明亮、低对比；装饰留在外侧。禁止任何文字、角色、场景、拼版或水印。Dark Academia / Gothic magic library。

### 答案卷轴

单个横向宽纸面卷轴按钮，透明背景，纸面尽量填满矩形，左右仅小型卷轴端头；暖象牙色、暗旧边缘、细金线与克制角纹；中央85%无标记，适合黑色动态文字。禁止文字、数字、图标、场景或拼版。避免高耸金属翼饰及窄丝带。

## 引擎接入

- 两张 PNG 由 `StyleBoxTexture` 九宫格复用；内容、按键提示和答案字母由 Godot 实时绘制。
- 答案六态：normal / hover / pressed / disabled / correct / wrong；正确、错误使用独立运行时色调。没有声称六张不同绘画素材。
- 三法术各有独立徽记 SVG 和独立色系边框 SVG。
- 顶部、状态与底部使用 `gothic_frame.svg`；阅读提示使用 `ribbon_frame.svg`。
- 法阵由 `rune_circle.svg`、原生柔光圆与阵营色边环组合。
- 缺图时纸面/边框安全回退为原生 StyleBoxFlat，缺失装饰跳过，原有角色程序回退保留。
- 静态绘制纹理由 `battle_theme.gd` 缓存，避免临时资源释放产生白块。
