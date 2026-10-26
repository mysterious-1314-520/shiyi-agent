import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiyi_agent_app/services/update_service.dart';
import 'package:shiyi_agent_app/widgets/markdown_text.dart';

void main() {
  test('appVersion 兜底常量与 pubspec 版本一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(
      pubspec,
    );
    expect(match, isNotNull, reason: 'pubspec.yaml 缺少 version 字段');
    final pubspecVersion = match!.group(1)!.split('+').first;
    expect(
      UpdateService.appVersion,
      pubspecVersion,
      reason:
          'UpdateService.appVersion 已过期：该常量在 PackageInfo 读取失败时作为'
          '本地版本参与更新比较，落后会导致误报「发现新版本」。发版改版本号时同步它。',
    );
  });

  group('UpdateService.compareVersion', () {
    test('相等版本返回 0', () {
      expect(UpdateService.compareVersion('1.1.5', '1.1.5'), 0);
    });

    test('高版本返回 1', () {
      expect(UpdateService.compareVersion('1.2.0', '1.1.9'), 1);
      expect(UpdateService.compareVersion('1.1.10', '1.1.9'), 1);
      expect(UpdateService.compareVersion('2.0.0', '1.9.9'), 1);
    });

    test('低版本返回 -1', () {
      expect(UpdateService.compareVersion('1.1.9', '1.2.0'), -1);
    });

    test('v 前缀不影响比较', () {
      expect(UpdateService.compareVersion('v1.1.5', '1.1.5'), 0);
      expect(UpdateService.compareVersion('v1.2.0', '1.1.5'), 1);
    });
  });

  testWidgets('更新弹窗用 Markdown 渲染更新说明', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => UpdateService.showUpdateAvailable(
              context,
              '1.1.7',
              '## 版本说明\n- 支持 Markdown',
            ),
            child: const Text('检查更新'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsOneWidget);
    expect(find.text('发现新版本 v1.1.7'), findsOneWidget);
    expect(find.byType(AdaptiveMarkdownText), findsOneWidget);
    expect(find.text('版本说明'), findsOneWidget);
    expect(find.text('支持 Markdown'), findsOneWidget);
    expect(find.text('稍后'), findsOneWidget);
    expect(find.text('下载更新'), findsOneWidget);
  });
}
