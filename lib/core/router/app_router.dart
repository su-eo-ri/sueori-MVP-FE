import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/categories/presentation/screens/category_learn_screen.dart';
import '../../features/favorites/presentation/screens/favorites_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/mypage/presentation/screens/mypage_screen.dart';
import '../../features/practice/presentation/screens/practice_screen.dart';
import '../../features/practice_sessions/presentation/screens/result_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    // Supabase OAuth 콜백 에러(예: ?error_code=identity_already_exists)가 붙은 채로
    // 리다이렉트되면 해시 경로가 알려진 라우트와 안 맞아 go_router 기본 에러 화면이
    // 뜬다 — 사용자에게 더 도움이 안 되니 홈으로 조용히 복구한다. 실제 에러 메시지는
    // main.dart에서 쿼리스트링을 따로 읽어 스낵바로 안내한다.
    errorBuilder: (context, state) => const HomeScreen(),
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/learn/:category',
        builder: (context, state) =>
            CategoryLearnScreen(categorySlug: state.pathParameters['category']!),
      ),
      GoRoute(
        path: '/practice/:wordId',
        builder: (context, state) => PracticeScreen(wordId: state.pathParameters['wordId']!),
      ),
      GoRoute(
        path: '/result/:sessionId',
        builder: (context, state) => ResultScreen(sessionId: state.pathParameters['sessionId']!),
      ),
      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),
      GoRoute(path: '/favorites', builder: (context, state) => const FavoritesScreen()),
      GoRoute(path: '/mypage', builder: (context, state) => const MyPageScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ],
  );
});
