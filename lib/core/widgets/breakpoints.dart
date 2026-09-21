import 'package:flutter/widgets.dart';

/// 웹 리디자인(2026-09-21, [[수어리 - 웹 리디자인 방향]]) 기준 단일 브레이크포인트.
/// `< wide`는 모바일(바텀 네비), `>= wide`는 와이드(톱 네비 + maxWidth 컨테이너).
class Breakpoints {
  Breakpoints._();

  static const double wide = 768;
  static const double contentMaxWidth = 1200;

  static bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= wide;
}
