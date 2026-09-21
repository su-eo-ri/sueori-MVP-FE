import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';

/// PRD §5.6 홈 — 카테고리 그리드. `/learn/:category`로 진입하는 시작점.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('수어리')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('카테고리를 불러오지 못했어요: $error')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('아직 등록된 카테고리가 없어요.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisExtent: 138,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) => _CategoryCard(category: categories[index]),
          );
        },
      ),
    );
  }
}

/// Card / Category (`04-Design` node `19:3`, 160×138) 스펙 구현.
class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsByCategoryProvider(category.id));

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.brandPrimary, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.category_outlined, color: Colors.white),
            ),
            const Spacer(),
            Text(category.name, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            // 진행률(N/M) 표기는 practice_sessions 집계가 필요해 채점 이식과 함께
            // 후속 작업으로 미룸 — 지금은 카테고리 단어 수만 보여줌.
            wordsAsync.when(
              data: (words) => Text('총 ${words.length}개 단어', style: AppTextStyles.bodySmall),
              loading: () => Text('불러오는 중...', style: AppTextStyles.bodySmall),
              error: (_, _) => Text('단어 수 확인 불가', style: AppTextStyles.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}
