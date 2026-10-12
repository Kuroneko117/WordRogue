# Web 版声音修复

2026-10-12。试玩：https://kuroneko117.github.io/WordRogue/

点击进入战斗后仍完全无声音的问题，在与已发布版本相同的 Web 包中复现。

浏览器 AudioContext 在点击后从 suspended 转为 running，音频缓冲区包含非零波形，但最终输出 RMS 和峰值仍为 0。另行生成的测试正弦音能通过同一测量链路输出，排除了测量链路本身的静音。说明此问题不只是浏览器首次自动播放限制，也不是漏打包音频文件。

Web 发布副本的 `project.godot` 加入：

```ini
[audio]
general/default_playback_type.web=0
```

该项目设置中 0 为 Stream，1 为 Sample；它与 AudioServer.PlaybackType 枚举的数值不是同一套值。修复仅覆盖 Web，原工程和 Windows 发布包保持原样。原音频、音量偏好及学习存档不变。

重新导出后的浏览器测量：

| 操作 | 修复前输出 RMS | 修复后输出 RMS |
| --- | ---: | ---: |
| 点击进入难度选择 | 0 | 0.002921 |
| 地图背景音乐 | 0 | 0.003059 |
| 战斗背景音乐 | 0 | 0.005519 |
| 作答及战斗音效 | 0 | 0.023336 |

作答阶段峰值为 0.119446；未捕获脚本错误。以上为浏览器音频输出波形测量，不代替用户设备上的人工试听。

Stream 的延迟可能比默认 Sample 更高，需后续在手机上试听性能；当前保留单线程和静态 GitHub Pages 托管。

更新后用 Ctrl+F5 刷新试玩页，等待加载完成，点击“开始冒险”。如仍无声，检查游戏“声音设置”中背景音乐与音效不为 0，以及浏览器标签页和系统音量未静音。不要清除站点数据，以免影响浏览器学习存档。

依据：[Godot Web 音频说明](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#id5)、[ProjectSettings 默认播放类型](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html#class-projectsettings-property-audio-general-default-playback-type-web)。
