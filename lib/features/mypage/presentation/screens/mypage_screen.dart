import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// PRD §5.6 마이페이지 최소 설정.
/// Figma 목업은 이메일/비밀번호 폼이었지만 실제 구현된 인증 구조는
/// 익명 세션 우선 + Google linkIdentity 업그레이드뿐이라 그 구조를 따른다.
class MyPageScreen extends ConsumerWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('마이페이지')),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: user.isAnonymous ? _GuestView(ref: ref) : _LoggedInView(user: user, ref: ref),
            ),
    );
  }
}

class _LoggedInView extends StatelessWidget {
  const _LoggedInView({required this.user, required this.ref});

  final User user;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final metadata = user.userMetadata;
    final avatarUrl = metadata?['avatar_url'] as String? ?? metadata?['picture'] as String?;
    final displayName =
        metadata?['full_name'] as String? ?? metadata?['name'] as String? ?? user.email ?? '사용자';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.bgSecondary,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          onBackgroundImageError: avatarUrl != null ? (_, _) {} : null,
          child: avatarUrl == null ? const Icon(Icons.person, size: 40, color: AppColors.textSecondary) : null,
        ),
        const SizedBox(height: 16),
        Text(displayName, style: AppTextStyles.h2),
        if (user.email != null) ...[
          const SizedBox(height: 4),
          Text(user.email!, style: AppTextStyles.bodySmall),
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
  const _GuestView({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('게스트로 학습 중', style: AppTextStyles.h3),
        const SizedBox(height: 8),
        Text(
          '로그인하면 학습 기록을 안전하게 보관하고 다른 기기에서도 이어갈 수 있어요.',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.brandPrimary),
          onPressed: () => _loginWithGoogle(context),
          child: const Text('Google로 로그인'),
        ),
      ],
    );
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      await ref.read(authRepositoryProvider).linkGoogleIdentity(redirectTo: Uri.base.toString());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인에 실패했어요: $e')));
      }
    }
  }
}
