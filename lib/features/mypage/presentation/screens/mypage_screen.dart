import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// PRD §5.6 마이페이지 최소 설정.
/// Figma 목업은 이메일/비밀번호 폼이었지만 실제 구현된 인증 구조는
/// 익명 세션 우선 + Google linkIdentity 업그레이드뿐이라 그 구조를 따른다.
/// 웹 리디자인(2026-09-21, [[수어리 - 웹 리디자인 방향]]) 반영: `Scaffold`+`AppBar`를
/// 공용 `AppShell`로 교체, 와이드에서 중앙 480~520px 컬럼 + 크림 배경 카드로 재배치.
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final wide = Breakpoints.isWide(context);

    return AppShell(
      currentIndex: 4,
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 20, vertical: wide ? 56 : 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: wide ? 520 : double.infinity),
                  child: Container(
                    padding: wide ? const EdgeInsets.all(40) : EdgeInsets.zero,
                    decoration: wide
                        ? BoxDecoration(color: AppColors.bgCream, borderRadius: BorderRadius.circular(24))
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('마이페이지', style: AppTextStyles.h1(context)),
                        SizedBox(height: wide ? 32 : 20),
                        user.isAnonymous
                            ? _GuestView(ref: ref, wide: wide)
                            : _LoggedInView(user: user, ref: ref, wide: wide),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _LoggedInView extends StatelessWidget {
  const _LoggedInView({required this.user, required this.ref, required this.wide});

  final User user;
  final WidgetRef ref;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final metadata = user.userMetadata;
    final avatarUrl = metadata?['avatar_url'] as String? ?? metadata?['picture'] as String?;
    final displayName =
        metadata?['full_name'] as String? ?? metadata?['name'] as String? ?? user.email ?? '사용자';
    final avatarRadius = wide ? 48.0 : 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: AppColors.bgSecondary,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          onBackgroundImageError: avatarUrl != null ? (_, _) {} : null,
          child: avatarUrl == null
              ? Icon(Icons.person, size: avatarRadius, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(height: 16),
        Text(displayName, style: wide ? AppTextStyles.h1(context) : AppTextStyles.h2),
        if (user.email != null) ...[
          const SizedBox(height: 4),
          Text(user.email!, style: wide ? AppTextStyles.bodyLarge(context) : AppTextStyles.bodySmall),
        ],
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => _signOut(context),
          child: const Text('로그아웃'),
        ),
      ],
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      await repo.ensureSignedIn();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그아웃에 실패했어요: $e')));
      }
    }
  }
}

class _GuestView extends StatelessWidget {
  const _GuestView({required this.ref, required this.wide});

  final WidgetRef ref;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('게스트로 학습 중', style: wide ? AppTextStyles.h1(context) : AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          '로그인하면 학습 기록을 안전하게 보관하고 다른 기기에서도 이어갈 수 있어요.',
          style: wide ? AppTextStyles.bodyLarge(context) : AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
          // 2026-09-22: 여기서 바로 linkGoogleIdentity를 호출하지 않고 전용 /login
          // 화면으로 이동 — 실제 인증 로직은 그대로 LoginScreen이 재사용한다.
          onPressed: () => context.push('/login'),
          child: const Text('Google로 로그인'),
        ),
      ],
    );
  }
}
