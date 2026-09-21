// Supabase 프로젝트 접속 정보. anon(publishable) key는 클라이언트에 노출되는 게
// 전제인 공개 키라 하드코딩해도 안전함 — RLS가 실제 접근 제어를 담당한다.
// poc/supabase_auth_poc, poc/oauth_web_poc에서 검증된 것과 동일한 값.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://kdtnjlvojaipppnxpnwt.supabase.co';
  static const String publishableKey = 'sb_publishable_x2loDw1WxBO1NyzymWpvOQ_HtQxLugc';
}
