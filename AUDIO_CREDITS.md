# 音频资源来源与许可（Audio Credits & Licenses）

`assets/audio/` 下的 4 个提示音已从**程序合成的电子音**替换为**真实录音**
（Wikimedia Commons / 开源 app 素材）。原始合成音备份在 `tool/backup/original_audio/`。

替换后的文件仍为 `44100Hz / 16-bit / 单声道 WAV`，文件名与 `pubspec.yaml`、
`lib/services/timer_audio.dart` 中的引用完全一致，**无需改动任何 Dart 代码**。

---

## 1. `clock_tick.wav` — 计时滴答

| 项目 | 内容 |
| --- | --- |
| 来源素材 | `WWS_Quartzclockticking.ogg` |
| 原始录制 | 20 世纪下半叶斯洛文尼亚产石英钟的真实走时声 |
| 录制者 | Work With Sounds / Technical Museum of Slovenia |
| 许可 | **CC BY 4.0**（需署名） |
| 来源页 | https://commons.wikimedia.org/wiki/File:WWS_Quartzclockticking.ogg |
| 处理 | 截取单次滴答 0.11s，归一化至 -1.4 dBFS |

## 2. `countdown_complete.wav` — 清脆铃声（默认）

| 项目 | 内容 |
| --- | --- |
| 来源素材 | `Sharp Bell.mp3` |
| 来源项目 | [papjamzzz/time](https://github.com/papjamzzz/time) —— 一个冥想计时器 PWA |
| 许可 | **MIT**（随仓库授权） |
| 处理 | 取起音后 1.5s，归一化至 -0.9 dBFS |

## 3. `countdown_soft.wav` — 柔和提示

| 项目 | 内容 |
| --- | --- |
| 来源素材 | `Smooth Bell.mp3` |
| 来源项目 | [papjamzzz/time](https://github.com/papjamzzz/time) |
| 许可 | **MIT**（随仓库授权） |
| 处理 | 取起音后 1.5s，归一化至 -0.9 dBFS |

## 4. `countdown_electronic.wav` — 电子提示

| 项目 | 内容 |
| --- | --- |
| 来源素材 | `NEC_PC-9801VX_ITF_beep_sound.ogg` |
| 原始录制 | NEC PC-9801VX 开机自检蜂鸣（V30 @10MHz）的真实录音 |
| 录制者 | Darklanlan |
| 许可 | **CC0**（公有领域奉献，无需署名） |
| 来源页 | https://commons.wikimedia.org/wiki/File:NEC_PC-9801VX_ITF_beep_sound.ogg |
| 处理 | 截取单次蜂鸣 0.40s，归一化至 -1.4 dBFS |

---

## 署名要求（上架/分发时）

- **CC BY 4.0**（`clock_tick.wav`）：需保留作者署名 "Work With Sounds / Technical
  Museum of Slovenia" 与许可声明，并注明做了裁剪与增益处理。
- **MIT**（`countdown_complete.wav`、`countdown_soft.wav`）：保留 MIT 许可声明即可。
- **CC0**（`countdown_electronic.wav`）：无署名义务。

建议在 app 的"关于/设置"页加一行：

> 提示音素材来自 Wikimedia Commons（CC BY 4.0 / CC0）与 papjamzzz/time（MIT）。

---

## 备选素材（已下载，可随时替换）

`tool/staging/` 中保留了全部候选素材，如需换风格可直接重新裁剪：

| 用途 | 备选 | 许可 |
| --- | --- | --- |
| 滴答 | `LA2_kitchen_clock.ogg`（塑料挂钟） | Public domain |
| 滴答 | `Clock_ticking.ogg` | Public domain |
| 铃声 | `Striking_a_bell_15cm_large.ogg`（15cm 铃） | Public domain |
| 铃声 | `Old_school_bell_4.ogg`（旧校铃） | Public domain |
| 铃声 | `Bristol_Chimes.ogg`（铃树） | CC BY 3.0 |
| 铃声 | `Windglockenspiel.Koshi.ogg`（Koshi 风铃） | CC0 |
| 铃声 | `SingingBowl1.ogg` / `SingingBowl2.ogg`（颂钵） | Public domain |
| 铃声 | `PureTime_bell.mp3`（冥想钟） | MIT |
| 电子音 | `Heart_Monitor_Beep.oga`（心电监护仪） | CC0 |
| 电子音 | `Sputnik_beep.ogg`（人造卫星信号） | Public domain |

## 工具

`tool/` 下是本仓库自用的音频处理脚本（Node，无需 ffmpeg）：

```bash
node tool/audio.js info   <file...>        # 时长/峰值/RMS/过零率
node tool/audio.js spectrum <file...>      # 分音/质心/频谱平坦度/衰减
node tool/audio.js plot   <file> [--from= --to=]   # ASCII 包络图
node tool/audio.js onsets <file>           # 起音点检测
node tool/audio.js cut    <in> <out.wav> [--onset=N|--at=sec] [--dur=sec] [--norm=0.9]
node tool/batchdl.js <manifest.json> <outdir>       # 带重试的批量下载
```

> `tool/node_modules/`、`tool/staging/` 为本地缓存，已加入 `.gitignore`。
