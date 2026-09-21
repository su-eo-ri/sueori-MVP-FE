import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/favorite.dart';

class FavoriteRepository {
  FavoriteRepository(this._client);

  final SupabaseClient _client;

  /// 현재 유저(RLS로 스코프됨)의 즐겨찾기/오답노트 전체.
  Future<List<Favorite>> fetchAllForCurrentUser() async {
    final rows = await _client.from('favorites').select().order('added_at', ascending: false);
    return rows.map(Favorite.fromJson).toList();
  }

  /// PRD §5.4 수동 추가. 이미 있으면(unique user_id+word_id) 무시.
  Future<void> addManual(String wordId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('로그인 세션이 없어 즐겨찾기를 추가할 수 없습니다.');
    await _client.from('favorites').upsert({
      'user_id': userId,
      'word_id': wordId,
      'source': FavoriteSource.manual.dbValue,
    }, onConflict: 'user_id,word_id');
  }

  Future<void> remove(String favoriteId) async {
    await _client.from('favorites').delete().eq('id', favoriteId);
  }
}
