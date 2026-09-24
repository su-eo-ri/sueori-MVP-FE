import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import 'breakpoints.dart';
import 'nav_destinations.dart';

/// Nav / Top — 와이드(≥768) 전용. [[수어리 - 웹 리디자인 방향]]: gdweb/Pinterest 둘 다
/// 하단 고정 탭바 대신 상단 수평 네비를 쓰는 것에서 착안, 사이드바를 대체함.
class AppTopNav extends StatelessWidget {
  const AppTopNav({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      // AppShell.body와 같은 `wideGutter`만 두고 가운데 정렬 캡은 없앤다 —
      // 로고/프로필 칩이 body 콘텐츠와 같은 좌우 기준선에 맞도록.
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Breakpoints.wideGutter),
        child: Row(
          children: [
            InkWell(
              onTap: () => context.go('/'),
              child: const Text(
                '수어리',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 48),
            // "학습" 탭(index 1)은 홈과 같은 경로라 톱네비에선 중복 링크로 안 보여주고
            // 홈/통계/즐겨찾기 3개만 노출(마이페이지는 우측 아바타 칩으로 분리).
            for (final i in const [0, 2, 3]) _TopNavLink(index: i, active: i == currentIndex),
            const Spacer(),
            _ProfileChip(active: currentIndex == 4),
          ],
        ),
      ),
    );
  }
}

class _TopNavLink extends StatelessWidget {
  const _TopNavLink({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final d = kNavDestinations[index];
    final color = active ? AppColors.brandPrimary : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: 32),
      child: InkWell(
        onTap: () {
          if (active) return;
          context.go(d.path);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(d.label, style: TextStyle(color: color, fontSize: 15, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 2,
              width: active ? 20 : 0,
              color: AppColors.brandPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandPrimary : AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        if (active) return;
        context.go('/mypage');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 20, color: color),
            const SizedBox(width: 6),
            Text('마이페이지', style: TextStyle(color: color, fontSize: 14, fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
