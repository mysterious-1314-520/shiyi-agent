import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../core/home_tabs.dart';

/// 主页底部悬浮液态玻璃 Tab 栏（拾忆 / DSH 共用，替换旧的贴底毛玻璃条）。
///
/// 外观走 `liquid_glass_easy` 自带的 [LiquidGlassTabBar] 单胶囊透镜：悬浮玻璃
/// 胶囊（折射 + 模糊背景）+ 选中胶囊在格子间滑动。布局守主页铁律：内容留白
/// 总高 [reservedHeight]（胶囊 [capsuleHeight] + 底部间隙 [bottomGap]），
/// 键盘弹起时由外层 `tabBarGap` 清零，胶囊本身贴 SafeArea 内侧悬浮。
///
/// 按压反馈：animated tier 的包内手势只有点按选中 + 长按拖 pill，没有按下
/// 视觉——按下去那一刻零反馈。这里在胶囊上叠一层 per-cell 高亮（translucent
/// [Listener] 不进手势竞技场，不拦包内 tap / 长按），按下 40ms 淡入、
/// 抬起 / 移出 150ms 淡出。
class LiquidBottomTabBar extends StatefulWidget {
  const LiquidBottomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeTabSpec> tabs;

  /// 内容区留白总高：胶囊 + 底部间隙，主页内容留白同值。
  static const double reservedHeight = 58;

  /// 玻璃胶囊高度。胶囊内 cell 高 = 本值 - 2×[itemPadding]，必须容下
  /// 图标 24 + 间隙 2 + 标签行高（约 15），留 5px 余量。
  static const double capsuleHeight = 54;

  /// 胶囊 rim 到图标行的内边距；也决定选中亮片的胶囊半径（cell 高 / 2）。
  static const double itemPadding = 4;

  /// 胶囊到 SafeArea 底边的悬浮间隙。
  static const double bottomGap = reservedHeight - capsuleHeight;

  /// 胶囊左右悬浮边距。
  static const double sideInset = 16;

  /// 按压高亮淡入时长（跟手）。
  static const Duration pressInDuration = Duration(milliseconds: 40);

  /// 按压高亮淡出时长（抬起 / 移出）。
  static const Duration pressOutDuration = Duration(milliseconds: 150);

  @override
  State<LiquidBottomTabBar> createState() => _LiquidBottomTabBarState();
}

class _LiquidBottomTabBarState extends State<LiquidBottomTabBar> {
  /// 当前按住的 cell 下标；-1 表示无按压。
  int _pressedCell = -1;

  /// 指针位置 → cell 下标。几何与包内手势区同源：cell 带从 itemPadding
  /// 起按 (宽 - 2×padding) / 栏数 均分（`LiquidGlassTabBarLayout`），
  /// 四周 padding 外按包语义不算任何 cell。
  int _cellAt(Offset p, double width) {
    final n = widget.tabs.length;
    if (n == 0) return -1;
    final x0 = LiquidBottomTabBar.itemPadding;
    if (p.dx < x0 || p.dx > width - x0) return -1;
    if (p.dy < x0 || p.dy > LiquidBottomTabBar.capsuleHeight - x0) return -1;
    final span = (width - 2 * x0) / n;
    if (span <= 0) return -1;
    final i = ((p.dx - x0) / span).floor();
    return (i < 0 || i >= n) ? -1 : i;
  }

  void _press(int cell) {
    if (cell == _pressedCell) return;
    setState(() => _pressedCell = cell);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final pillTint = dark ? const Color(0x2EFFFFFF) : const Color(0x33000000);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LiquidBottomTabBar.sideInset,
          0,
          LiquidBottomTabBar.sideInset,
          LiquidBottomTabBar.bottomGap,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final n = widget.tabs.length;
            final cellW =
                n > 0
                    ? (width - 2 * LiquidBottomTabBar.itemPadding) / n
                    : 0.0;
            final cellH =
                LiquidBottomTabBar.capsuleHeight -
                2 * LiquidBottomTabBar.itemPadding;
            return SizedBox(
              height: LiquidBottomTabBar.capsuleHeight,
              width: width,
              child: Listener(
                // translucent：Listener 自身命中但不进手势竞技场，
                // 包内 RawGestureDetector 的 tap / 长按照常收到事件。
                behavior: HitTestBehavior.translucent,
                onPointerDown:
                    (e) => _press(_cellAt(e.localPosition, width)),
                onPointerMove:
                    (e) => _press(_cellAt(e.localPosition, width)),
                onPointerUp: (_) => _press(-1),
                onPointerCancel: (_) => _press(-1),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    LiquidGlassTabBar(
                      items: [
                        for (final tab in widget.tabs)
                          LiquidGlassTabBarItem(
                            icon: tab.icon,
                            selectedIcon: tab.selectedIcon,
                            label: tab.label,
                          ),
                      ],
                      selectedIndex: widget.currentIndex,
                      onChanged: (index) {
                        if (index != widget.currentIndex) {
                          HapticFeedback.selectionClick();
                        }
                        widget.onTap(index);
                      },
                      width: width,
                      height: LiquidBottomTabBar.capsuleHeight,
                      itemPadding: LiquidBottomTabBar.itemPadding,
                      // Apple 材质：薄纱底色（55%/50%）+ 大模糊 + 下偏移接触影，
                      // 折射与光学边沿用包默认，读作 iOS 悬浮毛玻璃。
                      style: LiquidGlassTabBar.defaultStyle.copyWith(
                        appearance: LiquidGlassAppearance(
                          color: dark
                              ? const Color(0x801C1C1E)
                              : const Color(0x8CF2F2F7),
                          blur: const LiquidGlassBlur(sigmaX: 30, sigmaY: 30),
                          saturation: 1.15,
                          shadow: const LiquidGlassShadow(
                            blur: 24,
                            opacity: 0.2,
                            offset: Offset(0, 8),
                          ),
                        ),
                      ),
                      itemStyle: LiquidGlassTabItemStyle(
                        selectedColor: accent,
                        unselectedColor: dark
                            ? const Color(0xFF8E8E93)
                            : const Color(0x993C3C43),
                        iconSize: 24,
                        labelFontSize: 10.5,
                        iconLabelGap: 2,
                        selectedFontWeight: FontWeight.w500,
                        unselectedFontWeight: FontWeight.w400,
                      ),
                      pillStyle: LiquidGlassTabPillStyle(
                        animated: true,
                        color: pillTint,
                        // 亮片描边走 rest 形状的 borderColor（静止与滑动同源）：
                        // 暗底白 20% / 亮底黑 12% 发丝线，读作玻璃芯片。
                        rest: LiquidGlassStyle(
                          shape: LiquidGlassShape(
                            cornerRadius: cellH / 2,
                            borderWidth: 0.7,
                            borderColor: dark
                                ? const Color(0x33FFFFFF)
                                : const Color(0x1F000000),
                          ),
                          appearance: LiquidGlassAppearance(color: pillTint),
                        ),
                      ),
                    ),
                    // 按压高亮：每个 cell 常驻，按状态换 opacity 与进/出时长
                    //（按下 40ms 淡入、抬起 150ms 淡出），跟手移动时旧格缓消
                    // 新格快亮。IgnorePointer 保证不吃包内手势。
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: LiquidBottomTabBar.itemPadding + i * cellW,
                        top: LiquidBottomTabBar.itemPadding,
                        width: cellW,
                        height: cellH,
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: i == _pressedCell ? 1 : 0,
                            duration: i == _pressedCell
                                ? LiquidBottomTabBar.pressInDuration
                                : LiquidBottomTabBar.pressOutDuration,
                            curve: Curves.easeOut,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: dark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(cellH / 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
