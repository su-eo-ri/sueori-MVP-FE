import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/favorite_repository.dart';
import '../../domain/favorite.dart';

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(ref.watch(supabaseClientProvider));
});

final myFavoritesProvider = FutureProvider<List<Favorite>>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(favoriteRepositoryProvider).fetchAllForCurrentUser();
});
