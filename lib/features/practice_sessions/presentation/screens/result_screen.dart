import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/word.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../favorites/presentation/providers/favorite_providers.dart';
import '../../domain/practice_session.dart';
import '../providers/practice_session_providers.dart';

/// PRD §5.5 결과 화면 (`/result/:sessionId`).
class ResultScreen extends ConsumerWidget {
  const ResultScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(practiceSessionByIdProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('결과'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context) ? context.pop() : context.go('/'),
        ),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('결과를 불러오지 못했어요: $error')),
        data: (session) {
          if (session == null) {
            return _EmptyState(onBackHome: () => context.go('/'));
          }
          return _ResultBody(session: session);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onBackHome});

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('세션을 찾을 수 없어요', style: AppTextStyles.h3),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
            onPressed: onBackHome,
            child: const Text('홈으로'),
          ),
        ],
      ),
    );
  }
}

class _ResultBody extends ConsumerWidget {
  const _ResultBody({required this.session});

  final PracticeSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordAsync = ref.watch(wordByIdProvider(session.wordId));
    final categoriesAsync = ref.watch(categoriesProvider);

    return wordAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('단어 정보를 불러오지 못했어요: $error')),
      data: (word) {
        return categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('카테고리 정보를 불러오지 못했어요: $error')),
          data: (categories) {
            Category? category;
            if (word != null) {
              for (final c in categories) {
                if (c.id == word.categoryId) {
                  category = c;
                  break;
                }
              }
            }
            final passThreshold = category?.passThreshold ?? kDefaultPassThreshold;
            final passed = session.score >= passThreshold;
            return _ResultContent(session: session, word: word, passed: passed);
          },
        );
      },
    );
  }
}

class _ResultContent extends ConsumerWidget {
  const _ResultContent({required this.session, required this.word, required this.passed});

  final PracticeSession session;
  final Word? word;
  final bool passed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('${session.score}점', style: AppTextStyles.h2.copyWith(fontSize: 32)),
          const SizedBox(height: 8),
          _PassBadge(passed: passed),
          const SizedBox(height: 20),
          // ponytail: 실제 스켈레톤-실루엣 랜드마크 비교 오버레이는 landmark→SVG 렌더러가
          // 필요해 범위 밖. 대신 플레이스홀더 박스 + weakestLandmarks 인덱스 캡션만 표시.
          _ComparisonPlaceholder(weakestLandmarks: session.weakestLandmarks),
          const SizedBox(height: 20),
          if (word != null) Text(word!.term, style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Text(
            passed ? '정확하게 잘 표현했어요!' : '조금 더 연습해봐요.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/practice/${session.wordId}'),
                  child: const Text('다시 도전'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      await ref.read(favoriteRepositoryProvider).addManual(session.wordId);
                      messenger.showSnackBar(const SnackBar(content: Text('즐겨찾기에 추가했어요')));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(content: Text('즐겨찾기 추가에 실패했어요: $e')));
                    }
                  },
                  child: const Text('즐겨찾기 추가'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PassBadge extends StatelessWidget {
  const _PassBadge({required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: passed ? AppColors.stateSuccess : AppColors.stateError,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        passed ? '통과' : '재도전 필요',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ComparisonPlaceholder extends StatelessWidget {
  const _ComparisonPlaceholder({required this.weakestLandmarks});

  final List<int> weakestLandmarks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: const Center(
            child: Icon(Icons.compare_outlined, size: 48, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 8),
        if (weakestLandmarks.isNotEmpty)
          Text(
            '가장 어긋난 관절: ${weakestLandmarks.map((i) => '#$i').join(', ')}',
            style: AppTextStyles.bodySmall,
          ),
      ],
    );
  }
}
