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

/// PRD §5.6 홈 — 히어로 + 카테고리 그리드. `/learn/:category`로 진입하는 시작점.
/// 웹 리디자인(2026-09-21, [[수어리 - 웹 리디자인 방향]]) 반영: `AppBar` + 고정 160×138
/// 카드 그리드였던 걸 히어로 밴드 + 배경 교차(흰색→크림) + 반응형 그리드로 교체.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final wide = Breakpoints.isWide(context);

    return AppShell(
      currentIndex: 0,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroBand(wide: wide),
            Container(
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
                  Text('카테고리별로 배워볼까요?', style: AppTextStyles.h1(context)),
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
                          maxCrossAxisExtent: 240,
                          mainAxisExtent: 210,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) => _CategoryCard(category: categories[index]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBand extends StatelessWidget {
  const _HeroBand({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('오늘의 수어를\n배워볼까요?', style: AppTextStyles.display(context)),
        const SizedBox(height: 16),
        SizedBox(
          width: wide ? 380 : double.infinity,
          child: Text('카메라로 직접 따라 하고, 정확도까지 바로 확인해요.', style: AppTextStyles.bodyLarge(context)),
        ),
      ],
    );

    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(wide ? 0 : 20, wide ? 72 : 40, wide ? 0 : 20, wide ? 72 : 40),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: textColumn),
                const SizedBox(width: 48),
                const Expanded(child: SizedBox(height: 260, child: _CategoryCollage())),
              ],
            )
          : textColumn,
    );
  }
}

/// Pinterest식 비대칭 콜라주 착안(겹치고 살짝 기울어진 컬러 블록). 실제 사진 에셋
/// 없이 브랜드 팔레트 컬러 블록 + 아이콘으로 구성(에셋 파이프라인은 범위 밖).
class _CategoryCollage extends StatelessWidget {
  const _CategoryCollage();

  @override
  Widget build(BuildContext context) {
    Widget block({
      required double top,
      required double left,
      required double size,
      required Color color,
      required IconData icon,
      double angle = 0,
    }) {
      return Positioned(
        top: top,
        left: left,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.4),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        block(top: 40, left: 70, size: 140, color: AppColors.brandPrimary, icon: Icons.family_restroom, angle: -0.08),
        block(top: 0, left: 240, size: 110, color: AppColors.stateSuccess, icon: Icons.emoji_emotions_outlined, angle: 0.12),
        block(top: 140, left: 0, size: 100, color: AppColors.textPrimary, icon: Icons.waving_hand_outlined, angle: 0.1),
        block(top: 160, left: 210, size: 90, color: AppColors.stateWarning, icon: Icons.school_outlined, angle: -0.15),
      ],
    );
  }
}

/// Card / Category — 웹 리디자인 신규(이미지 블록이 카드 상단 절반을 채우는 형태).
class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(wordsByCategoryProvider(category.id));

    return HoverLift(
      onTap: () => context.push('/learn/${category.slug}'),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.brandPrimary,
                alignment: Alignment.center,
                child: const Icon(Icons.category_outlined, color: Colors.white, size: 40),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }
}
