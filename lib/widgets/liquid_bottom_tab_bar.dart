import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import '../core/home_tabs.dart';

/// 主页底部悬浮液态玻璃 Tab 栏（拾忆 / DSH 共用，替换旧的贴底毛玻璃条）。
///
/// 外观走 `liquid_glass_easy` 自带的 [LiquidGlassTabBar] 单胶囊透镜：悬浮玻璃
/// 胶囊（折射 + 模糊背景）+ 选中胶囊在格子间滑动。布局守主页铁律：内容留白
/// 总高 [reservedHeight]（胶囊 [capsuleHeight] + 底部间隙 [bottomGap]），
/// 键盘弹起时由外层 `tabBarGap` 清零，胶囊本身贴 SafeArea 内侧悬浮。
class LiquidBottomTabBar extends StatelessWidget {
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

  /// 玻璃胶囊高度。胶囊内 cell 高 = 本值 - 2×itemPadding，必须容下
  /// 图标 24 + 间隙 3 + 标签行高（约 15），留 4px 余量。
  static const double capsuleHeight = 54;

  /// 胶囊到 SafeArea 底边的悬浮间隙。
  static const double bottomGap = reservedHeight - capsuleHeight;

  /// 胶囊左右悬浮边距。
  static const double sideInset = 16;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(sideInset, 0, sideInset, bottomGap),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return LiquidGlassTabBar(
              items: [
                for (final tab in tabs)
                  LiquidGlassTabBarItem(
                    icon: tab.icon,
                    selectedIcon: tab.selectedIcon,
                    label: tab.label,
                  ),
              ],
              selectedIndex: currentIndex,
              onChanged: onTap,
              width: constraints.maxWidth,
              height: capsuleHeight,
              itemPadding: 4,
              // 底色 / 模糊强度对齐旧贴底条（90% 不透明 + 18 模糊），
              // 但降到 70%~80% 让折射透出底下内容，读作悬浮玻璃。
              style: LiquidGlassTabBar.defaultStyle.copyWith(
                appearance: LiquidGlassAppearance(
                  color: dark
                      ? const Color(0xB31C1C1E)
                      : const Color(0xCCF2F2F7),
                  blur: const LiquidGlassBlur(sigmaX: 18, sigmaY: 18),
                  saturation: 1.1,
                ),
              ),
              itemStyle: LiquidGlassTabItemStyle(
                selectedColor: accent,
                unselectedColor: dark
                    ? const Color(0xFF8E8E93)
                    : const Color(0x993C3C43),
                iconSize: 24,
                labelFontSize: 10.5,
                iconLabelGap: 3,
                selectedFontWeight: FontWeight.w600,
                unselectedFontWeight: FontWeight.w400,
              ),
              pillStyle: LiquidGlassTabPillStyle(
                animated: true,
                color: accent.withValues(alpha: dark ? .24 : .16),
              ),
            );
          },
        ),
      ),
    );
  }
}
