import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import 'core/config/supabase_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'features/auth/presentation/providers/auth_providers.dart';
import 'features/camera/presentation/camera_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 라우터가 알 수 없는 해시 경로를 `/`로 정리하기 전에 읽어둬야 한다.
  final oauthError = _readOAuthErrorParams();
  registerCameraView();
  // push로 연 화면(학습/연습/로그인)도 URL에 반영해야 새로고침·링크 공유 시 같은 화면이 열린다.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await Supabase.initialize(url: SupabaseConfig.url, publishableKey: SupabaseConfig.publishableKey);
  runApp(ProviderScope(child: SueoriApp(oauthError: oauthError)));
}

/// OAuth 실패 시 Supabase는 에러를 쿼리(`?error_code=`)나 해시(`#error_code=`,
/// `#/mypage?error_code=`)로 붙여 돌려보낸다 — 해시 라우팅이라 go_router는 못 보므로 직접 읽는다.
Map<String, String>? _readOAuthErrorParams() {
  final params = {...Uri.base.queryParameters};
  final fragment = Uri.base.fragment;
  final q = fragment.indexOf('?');
  final fragmentQuery = q >= 0 ? fragment.substring(q + 1) : (fragment.startsWith('/') ? '' : fragment);
  if (fragmentQuery.isNotEmpty) params.addAll(Uri.splitQueryString(fragmentQuery));
  return params.containsKey('error_code') || params.containsKey('error') ? params : null;
}

class SueoriApp extends ConsumerStatefulWidget {
  const SueoriApp({super.key, this.oauthError});

  final Map<String, String>? oauthError;

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
    if (widget.oauthError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOAuthError(widget.oauthError!));
    }
  }

  void _showOAuthError(Map<String, String> params) {
    // 새로고침할 때마다 같은 스낵바가 다시 뜨지 않도록 URL에서 에러 쿼리를 지운다.
    final hash = web.window.location.hash;
    final cleanHash = hash.startsWith('#/') ? hash.split('?').first : '#/';
    web.window.history.replaceState(null, '', '${Uri.base.path}$cleanHash');
    // `#/mypage?error=...`는 라우터가 쿼리째 경로로 들고 있어 다음 프레임에 URL을 되돌리므로 라우터도 옮긴다.
    if (hash.startsWith('#/') && hash.contains('?')) {
      ref.read(appRouterProvider).go(cleanHash.substring(1));
    }

    final alreadyLinked = params['error_code'] == 'identity_already_exists';
    final message = alreadyLinked
        ? '이 Google 계정은 이미 다른 프로필에 연결되어 있어요. 기존 계정으로 로그인하면 이 기기의 게스트 기록은 사라져요.'
        : params['error_description'] ?? '로그인 중 문제가 발생했어요. 다시 시도해주세요.';
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 10),
        action: alreadyLinked
            ? SnackBarAction(
                label: '기존 계정으로 로그인',
                onPressed: () => ref.read(authRepositoryProvider).signInWithGoogle(),
              )
            : null,
      ),
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
