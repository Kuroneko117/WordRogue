# WordRogue《遗忘书塔》

Godot 4.7.2 制作的单词学习与书塔冒险游戏。

## 在线试玩

[打开网页试玩](https://kuroneko117.github.io/WordRogue/)

首次加载需要下载约 54 MB。点击页面后允许播放音频。需要支持 WebAssembly 和 WebGL 2.0 的浏览器。

浏览器学习进度保存在当前站点 IndexedDB；清除站点数据可能清除进度，不与 Windows 存档自动同步。

## 工程与文件

- `web/`：已验证的单线程 Web 导出。
- [下载精简 Godot 工程](source/WordRogue-Clean-Source.zip)：解压后用 Godot 4.7.2 打开 project.godot，安装匹配的导出模板。
- `.github/workflows/wordrogue-pages.yml`：仅部署 web/ 到 GitHub Pages。

已检查本机 Chrome 下中文字体、难度选择、七层地图、首战作答、暂停及刷新后的学习存档；尚未完成全部七层通关及手机、Safari、Firefox 实机验收。

## 素材与许可

[许可与素材出处](https://kuroneko117.github.io/WordRogue/licenses.html)

音频有 CC0 来源记录，字体附 SIL OFL，ECDICT 词库附 MIT 原文。项目所有者于 2026-10-12 确认拥有角色、敌人和背景图用于公开试玩及随游戏分发的权利。第三方许可证不代表整个游戏或用户图片按 MIT/CC0 开源。

本仓库未包含原工程备份、测试缓存、原始设定图、Windows/Android 发布包或真实学习存档。
