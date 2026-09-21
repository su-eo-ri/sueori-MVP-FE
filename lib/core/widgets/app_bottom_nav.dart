import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Nav / Bottom (`04-Design` node `38:163`) — 최상위 탭 5개.
/// "학습" 탭은 별도 화면이 없어 홈(카테고리 그리드)으로 연결한다(둘 다 같은 콘텐츠).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({required this.currentIndex, super.key});

  final int currentIndex;

  static const _destinations = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈', path: '/'),
    (icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: '학습', path: '/'),
    (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: '통계', path: '/stats'),
    (icon: Icons.star_outline, activeIcon: Icons.star, label: '즐겨찾기', path: '/favorites'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지', path: '/mypage'),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppColors.brandPrimary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.surfaceCard,
      onTap: (index) {
        if (index == currentIndex) return;
        context.go(_destinations[index].path);
      },
      items: [
        for (final d in _destinations)
          BottomNavigationBarItem(icon: Icon(d.icon), activeIcon: Icon(d.activeIcon), label: d.label),
      ],
    );
  }
}
