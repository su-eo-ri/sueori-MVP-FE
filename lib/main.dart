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
  @override
  void initState() {
    super.initState();
    // PRD 정책: 로그인 화면 없이 앱 시작 시 익명 세션부터 확보.
    Future.microtask(() => ref.read(authRepositoryProvider).ensureSignedIn());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: '수어리',
      theme: ThemeData(
        colorSchemeSeed: AppColors.brandPrimary,
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansKrTextTheme(),
      ),
      routerConfig: router,
    );
  }
}
