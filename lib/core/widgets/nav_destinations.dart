import 'package:flutter/material.dart';

typedef NavDestination = ({IconData icon, IconData activeIcon, String label, String path});

/// [[수어리 - 웹 리디자인 방향]] — `AppBottomNav`(모바일)/`AppTopNav`(와이드)가 공유하는
/// 최상위 탭 5개. "학습" 탭은 별도 화면이 없어 홈(카테고리 그리드)으로 연결한다.
const kNavDestinations = <NavDestination>[
  (icon: Icons.home_outlined, activeIcon: Icons.home, label: '홈', path: '/'),
  (icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, label: '학습', path: '/'),
  (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: '통계', path: '/stats'),
  (icon: Icons.star_outline, activeIcon: Icons.star, label: '즐겨찾기', path: '/favorites'),
  (icon: Icons.person_outline, activeIcon: Icons.person, label: '마이페이지', path: '/mypage'),
];
