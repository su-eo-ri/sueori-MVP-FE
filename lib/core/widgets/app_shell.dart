import 'package:flutter/material.dart';

import 'app_bottom_nav.dart';
import 'app_top_nav.dart';
import 'breakpoints.dart';

/// [[수어리 - 웹 리디자인 방향]] 공용 셸 — 최상위 탭 화면(홈/학습/통계/즐겨찾기/마이페이지)이
/// 각자 `Scaffold(appBar: ..., bottomNavigationBar: ...)`를 반복하던 걸 대체.
/// 모바일(<768)은 바텀 네비, 와이드(≥768)는 톱 네비 + `contentMaxWidth` 중앙 컨테이너로 전환.
/// `/practice`, `/result`처럼 네비 없는 몰입형 화면은 이 셸을 쓰지 않는다.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentIndex,
    required this.body,
    this.backgroundColor,
    super.key,
  });

  final int currentIndex;
  final Widget body;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    if (wide) {
      return Scaffold(
        backgroundColor: backgroundColor ?? Colors.white,
        body: Column(
          children: [
            AppTopNav(currentIndex: currentIndex),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                  child: body,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.white,
      body: body,
      bottomNavigationBar: AppBottomNav(currentIndex: currentIndex),
    );
  }
}
