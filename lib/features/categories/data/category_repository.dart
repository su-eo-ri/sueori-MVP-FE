import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/category.dart';
import '../domain/word.dart';

class CategoryRepository {
  CategoryRepository(this._client);

  final SupabaseClient _client;

  Future<List<Category>> fetchCategories() async {
    final rows = await _client.from('categories').select().order('sort_order', ascending: true);
    return rows.map(Category.fromJson).toList();
  }

  Future<List<Word>> fetchWords(String categoryId) async {
    final rows = await _client
        .from('words')
        .select()
        .eq('category_id', categoryId)
        .order('sort_order', ascending: true);
    return rows.map(Word.fromJson).toList();
  }

  /// `/result`, `/favorites`처럼 카테고리 목록을 거치지 않고 단어 하나만 필요한 화면용.
  Future<Word?> fetchWordById(String wordId) async {
    final row = await _client.from('words').select().eq('id', wordId).maybeSingle();
    if (row == null) return null;
    return Word.fromJson(row);
  }
}
