import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/category_repository.dart';
import '../../domain/category.dart';
import '../../domain/word.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(supabaseClientProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).fetchCategories();
});

/// 카테고리 그리드(단어 수 표시)와 학습 화면(카드 덱)이 같은 카테고리 id로 이 provider를
/// 공유하므로, 그리드에서 이미 불러온 결과를 학습 화면 진입 시 재사용(refetch 없음).
final wordsByCategoryProvider = FutureProvider.family<List<Word>, String>((ref, categoryId) {
  return ref.watch(categoryRepositoryProvider).fetchWords(categoryId);
});

/// `/result`, `/favorites`처럼 카테고리 그리드를 거치지 않고 단어 id 하나만 아는 화면용.
final wordByIdProvider = FutureProvider.family<Word?, String>((ref, wordId) {
  return ref.watch(categoryRepositoryProvider).fetchWordById(wordId);
});

/// `/stats`, `/result`에서 category.passThreshold가 null일 때 적용할 전역 기본값.
/// DB 컬럼 자체엔 default가 없어(nullable), 이 값은 애플리케이션 레벨 정책이다(PRD 2026-09-02 결정).
const kDefaultPassThreshold = 80;
