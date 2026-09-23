import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/camera/presentation/camera_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerCameraView();
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  runApp(const ProviderScope(child: SueoriApp()));
}

class SueoriApp extends ConsumerStatefulWidget {
  const SueoriApp({super.key});

  @override
  ConsumerState<SueoriApp> createState() => _SueoriAppState();
}

class _SueoriAppState extends ConsumerState<SueoriApp> {
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    // PRD 정책: 로그인 화면 없이 앱 시작 시 익명 세션부터 확보.
    Future.microtask(() => ref.read(authRepositoryProvider).ensureSignedIn());
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOAuthErrorIfAny());
  }

  /// `linkIdentity(Google)` 리다이렉트가 실패하면 Supabase가 `?error_code=...`를
  /// 붙여서 앱으로 돌려보낸다(해시 라우팅이라 go_router는 이 쿼리스트링을 못 봄 —
  /// `Uri.base`로 직접 읽어야 함). 안내 없이 방치하면 사용자가 깨진 화면에 갇힌다.
  void _showOAuthErrorIfAny() {
    final params = Uri.base.queryParameters;
    final errorCode = params['error_code'];
    if (errorCode == null) return;
    final message = switch (errorCode) {
      'identity_already_exists' =>
        '이 Google 계정은 이미 다른 프로필에 연결되어 있어요. 다른 Google 계정으로 시도하거나, 기존 프로필로 로그인해주세요.',
      _ => params['error_description'] ?? '로그인 중 문제가 발생했어요. 다시 시도해주세요.',
    };
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '수어리',
      scaffoldMessengerKey: _scaffoldMessengerKey,
      theme: ThemeData(
        colorSchemeSeed: AppColors.brandPrimary,
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      routerConfig: router,
    );
  }
}
