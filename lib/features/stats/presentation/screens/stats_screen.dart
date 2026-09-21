import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../practice_sessions/presentation/providers/practice_session_providers.dart';

/// PRD §5.3 통계 — 카테고리별 평균 정답률 시각화, 약점 카테고리 강조, 탭하면 바로 학습 진입.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('카테고리를 불러오지 못했어요: $error')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('아직 등록된 카테고리가 없어요.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _CategoryStatsCard(category: categories[index]),
          );
        },
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

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/learn/${category.slug}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name, style: AppTextStyles.h3),
            const SizedBox(height: 8),
            body,
          ],
        ),
      ),
    );
  }
}
