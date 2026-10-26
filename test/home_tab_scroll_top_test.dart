import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi_agent_app/core/home_tab_scroll_top.dart';

/// 挂一棵超长列表树，返回其 ScrollController；供各用例 jumpTo 制造滚动量。
Future<ScrollController> _pumpList(WidgetTester tester) async {
  final ctrl = ScrollController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: ctrl,
          children: [for (var i = 0; i < 300; i++) SizedBox(height: 50, child: Text('row $i'))],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return ctrl;
}

void main() {
  setUp(HomeTabScrollTop.debugReset);
  tearDown(HomeTabScrollTop.debugReset);

  testWidgets('toTop 把已注册且滚动中的列表带回顶部', (tester) async {
    final ctrl = await _pumpList(tester);
    addTearDown(ctrl.dispose);
    ctrl.jumpTo(3000);
    await tester.pump();
    expect(ctrl.offset, greaterThan(0));

    HomeTabScrollTop.register(0, ctrl);
    // animateTo 靠 pump 驱动，先取 future 再推进帧，禁止直接 await（死锁）。
    final toTop = HomeTabScrollTop.toTop(0);
    await tester.pumpAndSettle();
    await toTop;
    expect(ctrl.offset, 0);
  });

  testWidgets('未注册的 tab 与未挂载的控制器静默返回', (tester) async {
    final ctrl = await _pumpList(tester);
    addTearDown(ctrl.dispose);
    ctrl.jumpTo(3000);
    await tester.pump();

    // 未注册：不炸、不误动别的控制器（early return，可直接 await）。
    await HomeTabScrollTop.toTop(1);
    expect(ctrl.offset, greaterThan(0));

    // 已注册但 hasClients=false（注册了没挂载）：静默（early return）。
    final unattached = ScrollController();
    addTearDown(unattached.dispose);
    HomeTabScrollTop.register(2, unattached);
    await HomeTabScrollTop.toTop(2);
    expect(unattached.hasClients, isFalse);
  });

  testWidgets('已在顶部（offset≈0）直接返回，不启动动画', (tester) async {
    final ctrl = await _pumpList(tester);
    addTearDown(ctrl.dispose);
    expect(ctrl.offset, 0);

    HomeTabScrollTop.register(0, ctrl);
    // 已在顶部分支 early return（offset≤0.01），可直接 await。
    await HomeTabScrollTop.toTop(0);
    await tester.pump();
    expect(ctrl.offset, 0);
  });

  testWidgets('身份校验：旧页 dispose 的 unregister 不清新页的注册', (tester) async {
    // 模拟引擎切换同下标换页的共存帧：新页 initState 先 register，旧页
    // dispose 后 unregister 自己——registry 必须仍指向新页。两页同树并存
    //（Column 各挂一个列表），与真实换页时序一致。
    final oldCtrl = ScrollController();
    final newCtrl = ScrollController();
    addTearDown(oldCtrl.dispose);
    addTearDown(newCtrl.dispose);
    Widget rows(ScrollController ctrl) => ListView(
      controller: ctrl,
      children: [
        for (var i = 0; i < 150; i++) SizedBox(height: 50, child: Text('row $i')),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [Expanded(child: rows(oldCtrl)), Expanded(child: rows(newCtrl))],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    oldCtrl.jumpTo(3000);
    newCtrl.jumpTo(3000);
    await tester.pump();
    expect(oldCtrl.offset, greaterThan(0));
    expect(newCtrl.offset, greaterThan(0));

    // 旧页 initState 注册 → 新页 initState 后跑覆盖 → 旧页 dispose 注销自己。
    HomeTabScrollTop.register(0, oldCtrl);
    HomeTabScrollTop.register(0, newCtrl);
    HomeTabScrollTop.unregister(0, oldCtrl);

    // toTop 仍作用于新页（animateTo 靠 pump 驱动：先取 future 再推进帧）；
    // 旧页控制器还在树上但已不在 registry，保持原位。
    final toTop = HomeTabScrollTop.toTop(0);
    await tester.pumpAndSettle();
    await toTop;
    expect(newCtrl.offset, 0);
    expect(oldCtrl.offset, greaterThan(0));
  });

  testWidgets('注销后 toTop 静默（列表还在但已无人注册）', (tester) async {
    final ctrl = await _pumpList(tester);
    addTearDown(ctrl.dispose);
    ctrl.jumpTo(3000);
    await tester.pump();

    HomeTabScrollTop.register(0, ctrl);
    HomeTabScrollTop.unregister(0, ctrl);
    await HomeTabScrollTop.toTop(0);
    expect(ctrl.offset, greaterThan(0));
  });
}
