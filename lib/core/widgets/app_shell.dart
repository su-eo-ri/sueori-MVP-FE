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
            // 예전엔 여기서 `contentMaxWidth`(1200)로 body를 가운데 정렬된 고정
            // 컬럼에 가뒀다 — 화면이 넓을수록 콘텐츠 크기와 무관하게 양옆
            // 여백만 커지는 문제가 있었음(피그마 웹 프레임 폭을 그대로 옮긴
            // 값이라 실제 위젯 레이아웃과 무관). 이제 고정 여백만 두고 폭은
            // body(주로 그리드)가 알아서 채우게 한다. 폭을 제한해야 하는
            // 화면(연습/결과/학습)은 각자 `Breakpoints.contentMaxWidth`로
            // 로컬 캡을 건다.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Breakpoints.wideGutter),
                child: body,
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
