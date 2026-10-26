# 底栏动效 Profile Runbook（任务 6）

量化主页底部悬浮 Tab 栏动效在真机上的帧耗时。**本 runbook 未在本会话执行**——
本环境无 `adb` / 无真机连接，以下为可复现步骤，拿到真机后照跑并回填数据。

## 前置

- 拾忆正式机（Android，开发者选项 → USB 调试已开）。
- 覆盖安装 profile 包（禁止卸载，保 app 数据）：

```bash
flutter build apk --profile
adb install -r build/app/outputs/flutter-apk/app-profile.apk
```

- 本环境 PATH：`export PATH=/opt/flutter/bin:$PATH`（见 AGENTS.md 构建隔离段）。

## 抓取

1. 连接真机，启动 DevTools 时间线：

```bash
flutter run --profile
```

2. 点击日志里的 DevTools 链接，打开 Performance 页，勾选 `Display notices`、
   `Track widget builds`，打开 `Flutter frames` 图。
3. 在手机上按下面脚本操作（每步之间停 500ms），全程保持 Performance 录制：

## 操作脚本（覆盖本轮改动的动效点）

| 步骤 | 操作 | 覆盖改动 |
| --- | --- | --- |
| A | 会话 tab → 功能 → 文件 → 终端，来回切 3 轮 | 换页 haptic + 选中 pill 滑动 |
| B | 按住「文件」格不放 1s，观察高亮淡入后移出到「功能」格再抬起 | 按压高亮 40/150ms + 跟手 |
| C | 会话列表滚到中部，点底部「会话」格两次（回顶） | `HomeTabScrollTop.toTop` 200ms |
| D | 输入框聚焦（键盘弹起）后点「功能」格 | 键盘态同 tab 收键盘 + 回顶 |
| E | 拾忆 ⇄ DSH 各做一遍 A（红绿灯切换引擎） | 同下标换页注册表 identity 防护 |

## 判读

- **通过**：全程 `Flutter frames` 无持续红帧；单帧 UI/Raster 耗时
  P90 ≤ 16.7ms、worst ≤ 33ms（60Hz 档按设备刷新率折算）。
- **可疑**：步骤 C 回顶动画期间连续红帧 → 查 `animateTo` 与回顶动画是否和
  `StaggeredSessions` 入场/挂载撞车（200ms easeOut 应无重活）。
- **可疑**：步骤 B 高亮淡入掉帧 → AnimatedOpacity 每帧 rebuild 4 个
  DecoratedBox，若 raster 超标改为只对 pressed cell setState。
- **步骤 D 判读**（键盘态可达性审计结论）：点格后焦点收起 + 列表回顶即符合
  预期。底栏结构上位于 Scaffold `bottom: 0`、`resizeToAvoidBottomInset:
  false`，IME 完全展开时被遮挡，可点时机为焦点残留窗口；Android back 键
  先由系统关 IME（不经 app），不属本项回归范围。

回填数据到本文件底部「执行记录」后即完成任务 6。

## 执行记录

- 2026-10-26：**未执行**（会话环境 `NO_ADB`，无真机）。待真机侧回填。
