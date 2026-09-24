import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../../core/widgets/hover_lift.dart';
import '../../../favorites/domain/favorite.dart';
import '../../../favorites/presentation/providers/favorite_providers.dart';
import '../../domain/category.dart';
import '../../domain/word.dart';
import '../providers/category_providers.dart';

/// PRD §5.2 학습 콘텐츠 — 플래시카드/암기장 (`/learn/:category`).
/// 웹 리디자인(2026-09-21, [[수어리 - 웹 리디자인 방향]]) 반영: `AppBar` 대신 `AppShell`,
/// 와이드에서는 카드 우측에 전체 단어 목록 패널을 추가.
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
      error: (error, _) => Scaffold(body: Center(child: Text('카테고리를 불러오지 못했어요: $error'))),
      data: (categories) {
        final matches = categories.where((c) => c.slug == widget.categorySlug);
        if (matches.isEmpty) {
          return const Scaffold(body: Center(child: Text('존재하지 않는 카테고리예요.')));
        }
        return _buildDeck(matches.first);
      },
    );
  }

  Widget _buildDeck(Category category) {
    final wordsAsync = ref.watch(wordsByCategoryProvider(category.id));

    return wordsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('단어를 불러오지 못했어요: $error'))),
      data: (words) {
        if (words.isEmpty) {
          return const Scaffold(body: Center(child: Text('이 카테고리엔 아직 단어가 없어요.')));
        }
        // index가 words 범위를 벗어나면(카테고리 전환 등) 안전하게 되돌림.
        if (_currentIndex >= words.length) _currentIndex = words.length - 1;
        final wide = Breakpoints.isWide(context);
        final content = Padding(
          padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 20, vertical: wide ? 32 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.name, style: AppTextStyles.h1(context)),
              SizedBox(height: wide ? 24 : 8),
              Expanded(child: wide ? _buildWide(words) : _buildMobile(words)),
            ],
          ),
        );
        return AppShell(
          currentIndex: 1,
          // 이 화면은 (플래시카드 고정폭 + 단어 목록) 2분할이라 `AppShell`의
          // 공용 여백만으로는 화면이 넓을수록 목록 패널이 한없이 늘어난다 —
          // 그래서 다른 화면과 달리 여기서만 로컬로 폭 캡을 건다.
          body: wide
              ? Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
                    child: content,
                  ),
                )
              : content,
        );
      },
    );
  }

  /// 기존 스와이프(PageView) + 점 인디케이터 — 로직/애니메이션 그대로 유지.
  Widget _buildMobile(List<Word> words) {
    return Column(
      children: [
        Text('${_currentIndex + 1} / ${words.length}', style: AppTextStyles.bodySmall),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: words.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) => Center(child: _FlashcardWidget(word: words[index])),
          ),
        ),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: _buildDots(words.length)),
      ],
    );
  }

  /// 와이드: 좌측 확대 플래시카드+화살표+인디케이터, 우측 전체 단어 목록 패널.
  Widget _buildWide(List<Word> words) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${_currentIndex + 1} / ${words.length}', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  _FlashcardWidget(word: words[_currentIndex], width: 400),
                  IconButton(
                    onPressed: _currentIndex < words.length - 1 ? () => setState(() => _currentIndex++) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDots(words.length),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: _WordListPanel(words: words, currentIndex: _currentIndex, onSelect: (i) => setState(() => _currentIndex = i))),
      ],
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
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
    );
  }
}

/// 와이드 전용 — 카테고리 전체 단어 목록, 현재 카드 하이라이트 + 클릭 시 점프.
class _WordListPanel extends StatelessWidget {
  const _WordListPanel({required this.words, required this.currentIndex, required this.onSelect});

  final List<Word> words;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: words.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final selected = index == currentIndex;
        return HoverLift(
          onTap: () => onSelect(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.brandPrimary.withValues(alpha: 0.1) : AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.brandPrimary : AppColors.borderDefault),
            ),
            child: Text(
              words[index].term,
              style: selected ? AppTextStyles.h3.copyWith(color: AppColors.brandPrimary) : AppTextStyles.h3,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      },
    );
  }
}

/// Card / Flashcard (`04-Design` node `19:7`, 280×313) 스펙 구현.
/// 와이드에서는 [width]로 확대(360~420px)해서 재사용.
class _FlashcardWidget extends ConsumerWidget {
  const _FlashcardWidget({required this.word, this.width = 280});

  final Word word;
  final double width;

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
      width: width,
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
              SizedBox(width: width, height: width * (200 / 280), child: _Thumbnail(url: word.thumbnailAsset)),
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
      // 국립국어원 이미지 서버가 CORS 헤더를 안 줘서 <img> 요소로 대체 표시
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
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
