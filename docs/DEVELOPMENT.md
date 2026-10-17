# 开发与构建说明

本文面向参与开发和维护的贡献者。下载安装与使用方法请先查看[用户说明](../README.md)。

## 快速开始

当前自动构建使用 Flutter 3.22.3（Dart 3.4.4）、JDK 17 和 Android SDK 35，建议本地与工作流使用相同的工具链。

```bash
# 安装依赖
flutter pub get

# 运行（连接设备或启动模拟器后）
flutter run

# 运行单元测试
flutter test

# 构建 Android Release APK
flutter build apk --release
```

Release APK 默认输出到：`build/app/outputs/flutter-apk/app-release.apk`。

本地默认构建号来自 `pubspec.yaml`，可能低于手机上已安装的自动发布版本。如果需要覆盖安装，请使用 `--build-number` 指定更大的构建号。

## 自动发布 Android 安装包

每次推送到 `main`，GitHub Actions 会执行代码检查、测试和 Release APK 构建，成功后更新固定的 [`latest` Release](https://github.com/mytechdream/timer-app/releases/tag/latest)。下载链接为 [timer-app-latest.apk](https://github.com/mytechdream/timer-app/releases/download/latest/timer-app-latest.apk)，同时提供 SHA-256 校验文件。

发布流程见 [android-release.yml](../.github/workflows/android-release.yml)。也可以在 [Actions 页面](https://github.com/mytechdream/timer-app/actions/workflows/android-release.yml)选择 `main`，点击 **Run workflow** 手动运行。较早提交的构建如果发现 `main` 已有新提交，会跳过发布，由新提交更新安装包；历史版本 Release 继续保留。

APK 版本名称取自 `pubspec.yaml`，构建号为其中的基础构建号加上工作流运行序号。例如 `1.1.0+2` 在首次自动构建时生成 `1.1.0+3`，后续运行递增。更新 `pubspec.yaml` 或变更工作流时，应确保新的 Android 构建号大于已发布版本，避免无法覆盖升级。

自动构建通过仓库 Secret `ANDROID_DEBUG_KEYSTORE_BASE64` 复用现有安装包的签名密钥。工作流将密钥解码到临时文件，并通过 `ANDROID_SIGNING_KEYSTORE_PATH` 显式传给 Gradle，发布前会校验 APK 签名，保证已安装版本可以覆盖升级。Secret 内容是现有 `debug.keystore` 的 Base64 编码，密钥文件不提交到仓库。迁移仓库或更换构建环境时，需要在 **Settings → Secrets and variables → Actions** 配置同名 Secret。

## 项目结构

```
lib/
├── main.dart            # 应用入口
├── app/                 # 根组件与全局状态
├── data/                # 数据仓库（SQLite / 内存实现）
├── models/              # 数据模型与默认预设
├── pages/               # 各页面（计时、批量、统计、历史、创建、设置）
├── services/            # 提示音等服务
├── theme/               # 主题与配色
├── utils/               # 工具函数
└── widgets/             # 通用组件
```

## 实现约定

- **历史记录**：倒计时在自然结束后写入历史；正计时在用户确认退出时写入历史。未开始或 0 秒正计时不会写入无意义记录。
- **默认倒计时**：设置页里的默认倒计时时长会影响首页倒计时滚轮、创建倒计时页面、批量计时添加倒计时弹层。
- **默认预设**：内置倒计时和内置标签可以删除；删除后会隐藏，不是永久移除系统模板。
- **标签去重**：新增或修改标签时，不能和当前可见的默认标签、自定义标签重复。
- **记录范围**：首页计时会话写入历史，当前批量计时不写入历史；历史保留最近 100 条。
- **统计口径**：数据洞察统一使用历史记录的名称字段汇总，因此倒计时名称和正计时标签都会参与“计时项/标签”统计。
- **日历折叠**：数据洞察日历的折叠状态只在当前页面会话内保留，暂不写入持久化设置。
- **计时准确性**：首页计时与批量倒计时按时间戳计算进度，回到应用后会校正显示时长。
- **批量倒计时提醒**：每个计时项独立提醒；暂停、重置或删除某一项只撤销对应提醒。通知或精确闹钟权限不可用时，计时页面会提示提醒可能缺失或延迟。

## Android 通知权限

结束提醒开启时，应用会在首页显示后请求通知权限，开始倒计时也会检查该权限。Android 13 及以上在尚未授权时可显示系统授权弹窗；Android 12 及以下没有这一运行时权限弹窗。不需要精确闹钟权限也能发通知；精确提醒的授权会在需要时单独请求，未授权时降级为可能延迟的普通调度。

如果以前拒绝过通知或系统不再弹出授权窗口，请长按应用图标进入“应用信息 → 通知”，允许通知，并检查声音、振动及悬浮通知设置。小米/红米手机锁屏或后台提醒仍受系统省电策略影响；需要后台提醒时，请同时检查自启动和电池限制。

通知使用专用的单色 `drawable/ic_stat_timer` 图标，与桌面图标分开；`res/raw/keep.xml` 保留动态引用的图标，避免 Release 资源压缩导致通知初始化失败。

Android 13 及以上的通知运行时权限行为参考 [Android 官方说明](https://developer.android.com/develop/ui/compose/notifications/notification-permission)。用户可以在系统中单独调整通知渠道的声音、振动等行为，相关机制见[通知渠道说明](https://developer.android.com/develop/ui/compose/notifications/channels)。

前台结束振动通过 Android 原生振动服务触发，后台振动由系统通知承担。当前振动通知渠道使用版本化配置；升级振动波形时，需要考虑已有渠道配置不会自动被覆盖，不能只修改默认通知参数。

## 文档与资源

- [用户说明](../README.md)：功能介绍、下载安装、使用方法和常见问题。
- [共享术语](../CONTEXT.md)：倒计时预设、正计时标签、计时会话和历史记录的概念。
- [音频素材与许可](../AUDIO_CREDITS.md)：提示音来源、素材处理和署名要求。
- 界面截图位于 screenshots/，README 中的截图路径相对于仓库根目录。
