import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/breakpoints.dart';
import 'app_colors.dart';

/// 04-Design 타이포 스케일(Noto Sans KR) + 웹 리디자인(2026-09-21) 확장분.
/// `display`/`h1`/`bodyLarge`는 [[수어리 - 웹 리디자인 방향]] 신규 토큰 —
/// 브레이크포인트별 값이 달라서 `BuildContext`를 받는 헬퍼로 제공.
class AppTextStyles {
  AppTextStyles._();

  /// 히어로 전용 초대형 타이틀.
  static TextStyle display(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    return GoogleFonts.notoSansKr(
      fontSize: wide ? 48 : 32,
      height: wide ? 56 / 48 : 40 / 32,
      fontWeight: FontWeight.w800,
      letterSpacing: wide ? -0.5 : -0.3,
      color: AppColors.textPrimary,
    );
  }

  /// 섹션 타이틀("오늘의 카테고리" 등).
  static TextStyle h1(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    return GoogleFonts.notoSansKr(
      fontSize: wide ? 32 : 24,
      height: wide ? 40 / 32 : 32 / 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle get h2 => GoogleFonts.notoSansKr(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get h3 => GoogleFonts.notoSansKr(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyLarge(BuildContext context) {
    final wide = Breakpoints.isWide(context);
    return GoogleFonts.notoSansKr(
      fontSize: 16,
      height: wide ? 26 / 16 : 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle get bodySmall => GoogleFonts.notoSansKr(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
