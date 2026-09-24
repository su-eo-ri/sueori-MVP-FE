import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'nav_destinations.dart';

/// Nav / Bottom — 모바일(<768) 전용. 웹 리디자인(2026-09-21)에서 라운드 플로팅
/// 필 스타일로 리터치(기존 Material 기본 `BottomNavigationBar` 느낌을 벗김).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < kNavDestinations.length; i++) _NavItem(index: i, currentIndex: currentIndex),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.index, required this.currentIndex});

  final int index;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final d = kNavDestinations[index];
    final active = index == currentIndex;
    final color = active ? AppColors.brandPrimary : AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (index == currentIndex) return;
        context.go(d.path);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? d.activeIcon : d.icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(d.label, style: TextStyle(color: color, fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
