import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../domain/favorite.dart';
import '../providers/favorite_providers.dart';

/// PRD §5.4 즐겨찾기 / 오답노트 — 수동 즐겨찾기와 채점 미달 자동 추가 항목을 한 목록에서 보여준다.
/// 자동 추가/해결 로직 자체는 채점 이식과 함께 서버 사이드(BE)에서 처리되며, 여기서는 조회/재도전
/// 진입/수동 삭제만 다룬다.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(myFavoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('즐겨찾기')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('즐겨찾기를 불러오지 못했어요: $error')),
        data: (favorites) {
          if (favorites.isEmpty) {
            return _EmptyState(onGoLearn: () => context.go('/'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _FavoriteRow(favorite: favorites[index]),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onGoLearn});

  final VoidCallback onGoLearn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('아직 즐겨찾기한 단어가 없어요', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '학습 중 마음에 드는 단어를 즐겨찾기하거나,\n틀린 단어를 여기서 다시 연습해보세요.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onGoLearn,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
              ),
              child: const Text('학습하러 가기'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card / Word (`04-Design`) 행 — 단어/카테고리는 개별 provider로 지연 로딩한다.
class _FavoriteRow extends ConsumerWidget {
  const _FavoriteRow({required this.favorite});

  final Favorite favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordAsync = ref.watch(wordByIdProvider(favorite.wordId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/practice/${favorite.wordId}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.bgSecondary, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.image_outlined, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: wordAsync.when(
                loading: () => const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, _) => Text('단어를 불러올 수 없어요', style: AppTextStyles.bodySmall),
                data: (word) {
                  if (word == null) {
                    return Text('삭제된 단어예요', style: AppTextStyles.bodySmall);
                  }
                  final categoryName = categoriesAsync.maybeWhen(
                    data: (categories) => _categoryNameFor(categories, word.categoryId),
                    orElse: () => '',
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(word.term, style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (categoryName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(categoryName, style: AppTextStyles.bodySmall),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            if (favorite.source == FavoriteSource.autoLowScore)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.stateError, borderRadius: BorderRadius.circular(12)),
                child: const Text('재도전 필요', style: TextStyle(color: Colors.white, fontSize: 11)),
              )
            else
              Icon(Icons.star, color: AppColors.brandPrimary),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: '즐겨찾기에서 삭제',
              onPressed: () => _remove(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryNameFor(List<Category> categories, String categoryId) {
    for (final category in categories) {
      if (category.id == categoryId) return category.name;
    }
    return '';
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(favoriteRepositoryProvider).remove(favorite.id);
      ref.invalidate(myFavoritesProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제하지 못했어요: $e')));
    }
  }
}
