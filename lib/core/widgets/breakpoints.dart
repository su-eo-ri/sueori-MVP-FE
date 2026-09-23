import 'package:flutter/widgets.dart';

/// 웹 리디자인(2026-09-21, [[수어리 - 웹 리디자인 방향]]) 기준 단일 브레이크포인트.
/// `< wide`는 모바일(바텀 네비), `>= wide`는 와이드(톱 네비 + maxWidth 컨테이너).
class Breakpoints {
  Breakpoints._();

  static const double wide = 768;

  /// 화면 가장자리 여백(와이드). 예전엔 이 값 대신 `contentMaxWidth`로 전체
  /// 콘텐츠를 가운데 정렬된 고정 폭 컬럼에 가뒀는데, 그 폭(1200)이 실제 위젯
  /// 크기가 아니라 Figma 웹 프레임 사이즈에서 그대로 따온 숫자라 1440px+
  /// 화면에서 양옆에 불필요하게 큰 여백만 남았다. 그리드류(홈/통계)는 이제
  /// 이 고정 여백만 두고, 각자의 `maxCrossAxisExtent`가 카드 크기를 정하면서
  /// 남는 폭만큼 컬럼 수가 자연히 늘어나게 한다([[수어리 - 웹 리디자인 방향]] 후속, 2026-09-22).
  static const double wideGutter = 48;

  /// 여전히 유효한 경우: 카드 그리드가 아니라 문단/폼처럼 한 줄이 너무 길면
  /// 읽기 힘든 콘텐츠(연습/결과/학습 화면의 좌우 2분할 레이아웃). 이런 화면은
  /// `wideGutter` 대신 각자 이 값으로 로컬 캡을 건다 — 공용 셸이 전체에
  /// 강제하지 않는다.
  static const double contentMaxWidth = 1200;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wide;
}
