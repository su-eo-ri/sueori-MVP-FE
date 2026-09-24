import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/reference_landmark_repository.dart';
import '../../domain/reference_landmark.dart';

final referenceLandmarkRepositoryProvider = Provider<ReferenceLandmarkRepository>((ref) {
  return ReferenceLandmarkRepository(ref.watch(supabaseClientProvider));
});

final referenceLandmarkByWordIdProvider = FutureProvider.family<ReferenceLandmark?, String>((ref, wordId) {
  return ref.watch(referenceLandmarkRepositoryProvider).fetchByWordId(wordId);
});
