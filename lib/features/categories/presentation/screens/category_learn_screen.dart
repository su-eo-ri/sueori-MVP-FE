import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../favorites/domain/favorite.dart';
import '../../../favorites/presentation/providers/favorite_providers.dart';
import '../../domain/category.dart';
import '../../domain/word.dart';
import '../providers/category_providers.dart';

/// PRD §5.2 학습 콘텐츠 — 플래시카드/암기장 (`/learn/:category`).
class CategoryLearnScreen extends ConsumerStatefulWidget {
  const CategoryLearnScreen({required this.categorySlug, super.key});

  final String categorySlug;

  @override
  ConsumerState<CategoryLearnScreen> createState() => _CategoryLearnScreenState();
}

class _CategoryLearnScreenState extends ConsumerState<CategoryLearnScreen> {
  final _pageController = PageController(viewportFraction: 0.86);
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('학습')),
        body: Center(child: Text('카테고리를 불러오지 못했어요: $error')),
      ),
      data: (categories) {
        final matches = categories.where((c) => c.slug == widget.categorySlug);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('학습')),
            body: const Center(child: Text('존재하지 않는 카테고리예요.')),
          );
        }
        return _buildDeck(matches.first);
      },
    );
  }

  Widget _buildDeck(Category category) {
    final wordsAsync = ref.watch(wordsByCategoryProvider(category.id));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: wordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('단어를 불러오지 못했어요: $error')),
        data: (words) {
          if (words.isEmpty) {
            return const Center(child: Text('이 카테고리엔 아직 단어가 없어요.'));
          }
          return Column(
            children: [
              const SizedBox(height: 8),
              Text(
                '${_currentIndex + 1} / ${words.length}',
                style: AppTextStyles.bodySmall,
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: words.length,
                  onPageChanged: (index) => setState(() => _currentIndex = index),
                  itemBuilder: (context, index) => Center(child: _FlashcardWidget(word: words[index])),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    words.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex ? AppColors.brandPrimary : AppColors.borderDefault,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Card / Flashcard (`04-Design` node `19:7`, 280×313) 스펙 구현.
class _FlashcardWidget extends ConsumerWidget {
  const _FlashcardWidget({required this.word});

  final Word word;

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref, Favorite? existing) async {
    try {
      if (existing == null) {
        await ref.read(favoriteRepositoryProvider).addManual(word.id);
      } else {
        await ref.read(favoriteRepositoryProvider).remove(existing.id);
      }
      ref.invalidate(myFavoritesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('즐겨찾기 처리에 실패했어요: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(myFavoritesProvider);
    final existingFavorite = favoritesAsync.maybeWhen(
      data: (favorites) {
        for (final f in favorites) {
          if (f.wordId == word.id) return f;
        }
        return null;
      },
      orElse: () => null,
    );
    final isFavorited = existingFavorite != null;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              SizedBox(width: 280, height: 200, child: _Thumbnail(url: word.thumbnailAsset)),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _toggleFavorite(context, ref, existingFavorite),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                      child: Icon(
                        isFavorited ? Icons.star : Icons.star_border,
                        color: isFavorited ? AppColors.brandPrimary : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(word.term, style: AppTextStyles.h2, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => context.push('/practice/${word.id}'),
                    child: const Text('연습하기'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return Container(color: AppColors.bgSecondary);
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.bgSecondary,
        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textSecondary),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: AppColors.bgSecondary, child: const Center(child: CircularProgressIndicator()));
      },
    );
  }
}
