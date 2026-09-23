import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../providers/auth_providers.dart';

/// `/login` — 마이페이지의 "Google로 로그인" CTA에서만 진입하는 전용 화면.
/// PRD의 "앱 시작 시 자동 익명 로그인, 로그인 화면 없음" 정책은 그대로 유지 —
/// 이 화면은 앱 진입을 막지 않고, 게스트가 계정을 "업그레이드"하고 싶을 때만
/// 명시적으로 찾아오는 선택적 경로다([[수어리 - 웹 리디자인 방향]] 후속 논의, 2026-09-22).
/// 실제 인증 로직(`linkGoogleIdentity`)은 기존 `AuthRepository`를 그대로 재사용 — 이
/// 화면은 진입 시점과 프레젠테이션만 바꾼 것이지 인증 방식 자체는 바꾸지 않았다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인에 실패했어요: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.bgCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go('/mypage'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 440 : double.infinity),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 24, vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 24, offset: Offset(0, 12))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: AppColors.brandPrimary, borderRadius: BorderRadius.circular(16)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.waving_hand_outlined, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 24),
                  Text('학습 기록을\n안전하게 보관하세요', style: AppTextStyles.h1(context)),
                  const SizedBox(height: 12),
                  Text(
                    'Google 계정으로 연결하면 지금까지의 진행 상황이 그대로 유지된 채,\n'
                    '다른 기기에서도 이어서 학습할 수 있어요.',
                    style: AppTextStyles.bodyLarge(context),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _loading ? null : () => _run(ref.read(authRepositoryProvider).linkGoogleIdentity),
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(_loading ? '연결하는 중...' : 'Google로 계속하기'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 다른 기기에서 이미 Google을 연결한 사용자는 linkIdentity가 항상
                  // identity_already_exists로 실패하므로 기존 계정 로그인 경로가 따로 필요하다.
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : () => _run(ref.read(authRepositoryProvider).signInWithGoogle),
                      child: Text('이미 연결한 계정이 있나요? 기존 계정으로 로그인', style: AppTextStyles.bodySmall),
                    ),
                  ),
                  Center(
                    child: Text(
                      '이 기기의 게스트 기록은 이어지지 않아요',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton(
                      onPressed: () => context.canPop() ? context.pop() : context.go('/mypage'),
                      child: Text('나중에 할게요', style: AppTextStyles.bodySmall),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
