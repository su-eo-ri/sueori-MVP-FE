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
    // 알 수 없는 경로(OAuth 에러 프래그먼트 `#error=...` 포함)는 URL까지 `/`로 정리한다.
    // OAuth 에러 파라미터는 main()에서 runApp 전에 미리 읽어두므로 여기서 지워도 된다.
    onException: (_, _, router) => router.go('/'),
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
