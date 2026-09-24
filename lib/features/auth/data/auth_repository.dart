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

  /// OAuth 완료 후 복귀 지점. `#/login`으로 돌아오면 이미 연결된 상태에서 로그인
  /// 화면이 다시 보이므로 마이페이지로 보낸다.
  static String get oauthRedirect => '${Uri.base.origin}/#/mypage';

  /// 익명 계정을 Google 계정으로 업그레이드. release 빌드에서만 정상 동작
  /// 확인됨(poc/oauth_web_poc) — 디버그 모드는 Google이 CDP 연결을 감지해 차단.
  Future<void> linkGoogleIdentity() {
    return _client.auth.linkIdentity(OAuthProvider.google, redirectTo: oauthRedirect);
  }

  /// 이미 Google이 연결된 기존 계정으로 복귀(새 기기 등). 현재 익명 세션의 게스트
  /// 기록은 버려진다 — PRD Non-Goal("게스트 데이터 영속성 보장 안 함")과 일치.
  Future<void> signInWithGoogle() {
    return _client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: oauthRedirect);
  }

  Future<void> signOut() => _client.auth.signOut();
}
