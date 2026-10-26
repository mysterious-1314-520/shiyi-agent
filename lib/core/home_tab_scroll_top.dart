import 'package:flutter/widgets.dart';

/// 主页 tab「再点一次当前 tab 回到列表顶部」注册表。
///
/// 各 tab 子页在 initState 把自己的主滚动控制器按 tab 下标注册进来，
/// dispose 注销；`_selectTab` 同 tab 分支调用 [toTop]。终端（下标 3）
/// 的 scrollback 由 live 输出管，首版不注册。
///
/// 引擎切换（拾忆 ⇄ DSH）时同下标换页：新页 initState 先于旧页 dispose
///（deactivate 延迟到帧末），所以注销必须做身份校验，只清掉仍是自己的
/// 注册，避免旧页把新页的条目抹掉。
class HomeTabScrollTop {
  HomeTabScrollTop._();

  static final Map<int, ScrollController> _registry = {};

  static void register(int tab, ScrollController controller) {
    _registry[tab] = controller;
  }

  static void unregister(int tab, ScrollController controller) {
    if (identical(_registry[tab], controller)) {
      _registry.remove(tab);
    }
  }

  /// 已在顶部 / 无挂载 / 未注册时静默返回。
  /// `ScrollController.animateTo` 对全部 attached positions 生效——同 tab
  /// 页面里互斥的主列表与搜索列表挂同一控制器，同一时刻只挂一个，不冲突。
  static Future<void> toTop(int tab) async {
    final controller = _registry[tab];
    if (controller == null || !controller.hasClients) return;
    if (controller.offset <= 0.01) return;
    await controller.animateTo(
      0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// 仅测试用：清空注册表，避免跨用例残留。
  static void debugReset() => _registry.clear();
}
