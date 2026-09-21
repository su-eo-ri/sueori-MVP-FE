import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/practice_session_repository.dart';
import '../../domain/practice_session.dart';

final practiceSessionRepositoryProvider = Provider<PracticeSessionRepository>((ref) {
  return PracticeSessionRepository(ref.watch(supabaseClientProvider));
});

/// `/stats`에서 카테고리별 집계에 쓰는 원본 목록. 인증 상태가 바뀌면(로그인/로그아웃)
/// 자동으로 다시 조회되도록 `currentUserProvider`를 watch한다.
final myPracticeSessionsProvider = FutureProvider<List<PracticeSession>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(practiceSessionRepositoryProvider).fetchAllForCurrentUser();
});

final practiceSessionByIdProvider = FutureProvider.family<PracticeSession?, String>((ref, sessionId) {
  return ref.watch(practiceSessionRepositoryProvider).fetchById(sessionId);
});
