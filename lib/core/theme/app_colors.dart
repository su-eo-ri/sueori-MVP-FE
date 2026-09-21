import 'package:flutter/widgets.dart';

/// 04-Design 컴포넌트 스펙(2026-09-18) 기준 색상 토큰. 실제 화면에서 쓰는 것만 옮김.
class AppColors {
  AppColors._();

  static const brandPrimary = Color(0xFFF6511D);
  static const brandPrimaryHover = Color(0xFFD6430F);
  static const textPrimary = Color(0xFF0D2C54);
  static const textSecondary = Color(0xFF4F5A6B);
  static const bgSecondary = Color(0xFFF7F8FA);
  /// 웹 리디자인(2026-09-21) 신규 — 섹션 배경 교차용 따뜻한 아이보리.
  /// 카드/폼 배경엔 쓰지 않음, 홈/스탯 등 섹션 밴드 전용.
  static const bgCream = Color(0xFFF5F1EA);
  static const borderDefault = Color(0xFFDEE3EA);
  static const surfaceCard = Color(0xFFFFFFFF);
  static const cardShadow = Color(0x140D2B54);

  static const stateSuccess = Color(0xFF7FB800);
  static const stateSuccessText = Color(0xFF5C8A00);
  static const stateError = Color(0xFFE5484D);
  static const stateWarning = Color(0xFFFFB400);
}
