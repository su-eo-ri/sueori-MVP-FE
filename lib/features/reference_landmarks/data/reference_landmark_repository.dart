import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/reference_landmark.dart';

class ReferenceLandmarkRepository {
  ReferenceLandmarkRepository(this._client);

  final SupabaseClient _client;

  /// 단어당 레퍼런스가 여러 버전 있을 수 있어(재촬영 등) 가장 최근 것만 사용.
  Future<ReferenceLandmark?> fetchByWordId(String wordId) async {
    final row = await _client
        .from('reference_landmarks')
        .select()
        .eq('word_id', wordId)
        .order('captured_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return ReferenceLandmark.fromJson(row);
  }
}
