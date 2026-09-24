import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/practice_session.dart';

class PracticeSessionRepository {
  PracticeSessionRepository(this._client);

  final SupabaseClient _client;

  /// `/stats` 집계용 — 현재 로그인된 유저(RLS로 본인 것만 반환됨)의 전체 시도 기록.
  Future<List<PracticeSession>> fetchAllForCurrentUser() async {
    final rows = await _client.from('practice_sessions').select().order('created_at');
    return rows.map(PracticeSession.fromJson).toList();
  }

  /// RLS가 익명 유저의 무료 카테고리 외 시도나 4회째 시도를 42501로 거부한다.
  Future<PracticeSession> insert({
    required String userId,
    required String wordId,
    required int score,
    required Map<String, dynamic> comparisonSummary,
    String? retryOfSessionId,
  }) async {
    final row = await _client
        .from('practice_sessions')
        .insert({
          'user_id': userId,
          'word_id': wordId,
          'score': score,
          'comparison_summary': comparisonSummary,
          'retry_of_session_id': ?retryOfSessionId,
        })
        .select()
        .single();
    return PracticeSession.fromJson(row);
  }

  /// `/result/:sessionId` 조회용. 없으면 null(RLS로 막혔거나 존재하지 않는 id).
  Future<PracticeSession?> fetchById(String sessionId) async {
    final row = await _client.from('practice_sessions').select().eq('id', sessionId).maybeSingle();
    if (row == null) return null;
    return PracticeSession.fromJson(row);
  }
}
