import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/scoring_service.dart';

final scoringServiceProvider = Provider<ScoringService>((ref) {
  return const ScoringService();
});
