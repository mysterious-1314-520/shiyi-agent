import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shiyi_agent_app/core/home_tabs.dart';
import 'package:shiyi_agent_app/widgets/liquid_bottom_tab_bar.dart';

void main() {
  test('内容留白 = 胶囊 54 + 底隙 4，总高保持 58', () {
    expect(LiquidBottomTabBar.reservedHeight, 58);
    expect(LiquidBottomTabBar.capsuleHeight, 54);
    expect(LiquidBottomTabBar.bottomGap, 4);
    expect(
      LiquidBottomTabBar.reservedHeight,
      LiquidBottomTabBar.capsuleHeight + LiquidBottomTabBar.bottomGap,
    );
    expect(LiquidBottomTabBar.sideInset, 16);
  });

  testWidgets('四栏文字渲染在悬浮胶囊里，点按回调下标', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: const Color(0xFF111111)),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LiquidBottomTabBar(
                  currentIndex: 1,
                  tabs: HomeTabs.shiyi,
                  onTap: taps.add,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 包用 forceSelected:false/true 两份图标行 + ClipPath 裁剪实现
    // 滑动 pill（见 liquid_glass_nav_bar_animated_content.dart:148-174），
    // 每个 label 天然渲染两份，视觉上 pill 内外各显一份。
    for (final label in HomeTabs.shiyi.map((e) => e.label)) {
      expect(find.text(label), findsWidgets);
    }

    // 目标 Text 在 IgnorePointer 的双份图标行里，点击由顶层 TapRow 接收
    //（同位置同 cell），静默 warnIfMissed。
    await tester.tap(find.text('文件').first, warnIfMissed: false);
    await tester.pump();
    expect(taps, [2]);
    // 悬浮几何：胶囊左右各悬浮 16、高 54、底隙 4（相对 Scaffold 底）。
    final capsule = find.byType(LiquidGlassTabBar);
    final scaffoldWidth = tester.getSize(find.byType(Scaffold)).width;
    final scaffoldHeight = tester.getSize(find.byType(Scaffold)).height;
    expect(tester.getSize(capsule).width, scaffoldWidth - 2 * LiquidBottomTabBar.sideInset);
    expect(tester.getSize(capsule).height, LiquidBottomTabBar.capsuleHeight);
    expect(tester.getTopLeft(capsule).dx, LiquidBottomTabBar.sideInset);
    expect(
      tester.getBottomLeft(capsule).dy,
      scaffoldHeight - LiquidBottomTabBar.bottomGap,
    );
  });

  testWidgets('外层 SafeArea(top:false)：不因状态栏高度上下偏移', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LiquidBottomTabBar(
              currentIndex: 0,
              tabs: HomeTabs.dsh,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Size size = tester.getSize(
      find.byType(LiquidBottomTabBar),
    );
    expect(size.height, LiquidBottomTabBar.reservedHeight);
    expect(size.width, tester.getSize(find.byType(Scaffold)).width);
  });
}
