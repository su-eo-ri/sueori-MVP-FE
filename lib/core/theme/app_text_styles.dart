import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// 04-Design 타이포 스케일(Noto Sans KR, 2026-09-18) 중 실제로 쓰는 스타일만.
class AppTextStyles {
  AppTextStyles._();

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

  static TextStyle get bodySmall => GoogleFonts.notoSansKr(
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
