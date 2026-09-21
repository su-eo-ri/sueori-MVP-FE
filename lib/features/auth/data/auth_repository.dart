import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// PRD 정책: 로그인 화면 없이 앱 시작 시 익명 세션을 먼저 확보한다.
  Future<void> ensureSignedIn() async {
    if (_client.auth.currentSession == null) {
      await _client.auth.signInAnonymously();
    }
  }

  /// 익명 계정을 Google 계정으로 업그레이드. release 빌드에서만 정상 동작
  /// 확인됨(poc/oauth_web_poc) — 디버그 모드는 Google이 CDP 연결을 감지해 차단.
  Future<void> linkGoogleIdentity({required String redirectTo}) {
    return _client.auth.linkIdentity(OAuthProvider.google, redirectTo: redirectTo);
  }

  Future<void> signOut() => _client.auth.signOut();
}
