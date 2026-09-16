import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// 세션 유무와 무관하게 현재 유저를 최대한 최신 값으로 노출.
/// authStateProvider 스트림이 아직 값을 안 냈어도(첫 프레임) currentUser로 폴백.
final currentUserProvider = Provider<User?>((ref) {
  final streamUser = ref.watch(authStateProvider).value?.session?.user;
  return streamUser ?? ref.watch(authRepositoryProvider).currentUser;
});
