import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('换页发一次 selectionClick 触感；重复点当前 tab 不发但回调仍上抛', (
    tester,
  ) async {
    final haptics = <MethodCall>[];
    final taps = <int>[];
    // 主页 _selectTab 换页后 setState 重建底栏；这里用 ValueNotifier 模拟
    // 同一行为，currentIndex 才会跟着 onTap 走。
    final currentIndex = ValueNotifier<int>(1);
    addTearDown(currentIndex.dispose);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<int>(
              valueListenable: currentIndex,
              builder: (context, idx, _) => LiquidBottomTabBar(
                currentIndex: idx,
                tabs: HomeTabs.shiyi,
                onTap: (i) {
                  taps.add(i);
                  currentIndex.value = i;
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 点非当前 tab：一次触感 + 换页回调。
    await tester.tap(find.text('文件').first, warnIfMissed: false);
    await tester.pump();
    final selectionVibrations = haptics
        .where((c) => c.method == 'HapticFeedback.vibrate')
        .toList();
    expect(selectionVibrations, hasLength(1));
    expect(selectionVibrations.single.arguments, 'HapticFeedbackType.selectionClick');
    expect(taps, [2]);

    // 再点当前 tab（下标 2）：不发触感，但回调必须照常上抛——
    // 主页 _selectTab 同 tab 分支靠它收键盘 + 回顶（键盘态可达性前提）。
    haptics.clear();
    await tester.tap(find.text('文件').first, warnIfMissed: false);
    await tester.pump();
    expect(
      haptics.where((c) => c.method == 'HapticFeedback.vibrate'),
      isEmpty,
    );
    expect(taps, [2, 2]);
  });

  testWidgets('按压高亮：pointer down 覆盖对应 cell，up 后 150ms 淡出', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: LiquidBottomTabBar(
              currentIndex: 0,
              tabs: HomeTabs.shiyi,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.getRect(find.byType(LiquidBottomTabBar));
    // 按在第 3 格（文件）中心。
    final cellWidth =
        (bar.width - 2 * LiquidBottomTabBar.itemPadding) / HomeTabs.shiyi.length;
    final pressOffset = Offset(
      LiquidBottomTabBar.itemPadding + 2.5 * cellWidth,
      LiquidBottomTabBar.capsuleHeight / 2,
    );
    final gesture = await tester.startGesture(
      bar.topLeft + pressOffset,
    );
    // 40ms 淡入完成后按压格完全不透明。
    await tester.pump(LiquidBottomTabBar.pressInDuration);
    final opacities = tester
        .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
        .map((w) => w.opacity)
        .toList();
    expect(opacities.where((o) => o == 1), hasLength(1));

    await gesture.up();
    await tester.pump(LiquidBottomTabBar.pressOutDuration);
    expect(
      tester
          .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
          .every((w) => w.opacity == 0),
      isTrue,
    );
  });
}
