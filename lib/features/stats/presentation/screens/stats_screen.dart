import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../../core/widgets/hover_lift.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../practice_sessions/presentation/providers/practice_session_providers.dart';

/// PRD §5.3 통계 — 카테고리별 평균 정답률 시각화, 약점 카테고리 강조, 탭하면 바로 학습 진입.
/// 웹 리디자인(2026-09-21, [[수어리 - 웹 리디자인 방향]]) 반영: `AppBar` + 세로 리스트였던 걸
/// `AppShell` + 배경 교차(크림) + 반응형 그리드로 교체(집계 로직은 변경 없음).
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final wide = Breakpoints.isWide(context);

    return AppShell(
      currentIndex: 2,
      body: SingleChildScrollView(
        child: Container(
          color: AppColors.bgCream,
          padding: EdgeInsets.fromLTRB(
            wide ? 0 : 20,
            wide ? 48 : 32,
            wide ? 0 : 20,
            wide ? 64 : 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('학습 통계', style: AppTextStyles.h1(context)),
              const SizedBox(height: 20),
              categoriesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('카테고리를 불러오지 못했어요: $error')),
                ),
                data: (categories) {
                  if (categories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('아직 등록된 카테고리가 없어요.')),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 280,
                      mainAxisExtent: 168,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) => _CategoryStatsCard(category: categories[index]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryStatsCard extends ConsumerWidget {
  const _CategoryStatsCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsByCategoryProvider(category.id));
    final sessionsAsync = ref.watch(myPracticeSessionsProvider);

    Widget body;
    if (wordsAsync.isLoading || sessionsAsync.isLoading) {
      body = Text('불러오는 중...', style: AppTextStyles.bodySmall);
    } else if (wordsAsync.hasError) {
      body = Text('단어 정보를 불러오지 못했어요.', style: AppTextStyles.bodySmall);
    } else if (sessionsAsync.hasError) {
      body = Text('기록을 불러오지 못했어요.', style: AppTextStyles.bodySmall);
    } else {
      final wordIds = wordsAsync.requireValue.map((w) => w.id).toSet();
      final scores = sessionsAsync.requireValue
          .where((s) => wordIds.contains(s.wordId))
          .map((s) => s.score)
          .toList();

      if (scores.isEmpty) {
        body = Text('아직 시도한 기록이 없어요', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary));
      } else {
        final average = scores.reduce((a, b) => a + b) / scores.length;
        final threshold = category.passThreshold ?? kDefaultPassThreshold;
        final isWeak = average < threshold;
        final barColor = isWeak ? AppColors.stateError : AppColors.stateSuccess;

        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('평균 ${average.round()}%', style: AppTextStyles.bodySmall.copyWith(color: barColor)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: average / 100,
                minHeight: 8,
                color: barColor,
                backgroundColor: AppColors.bgSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text('${scores.length}회 시도', style: AppTextStyles.bodySmall),
          ],
        );
      }
    }

    return HoverLift(
      onTap: () => context.push('/learn/${category.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            body,
          ],
        ),
      ),
    );
  }
}
