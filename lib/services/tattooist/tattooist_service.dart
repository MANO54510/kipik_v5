// lib/services/tattooist_service.dart

import 'dart:math';
import '../../models/tattooist.dart';

class TattooistService {
  // Mock data pour le développement
  final List<Tattooist> _mockTattooists = List.generate(
    10,
    (index) => Tattooist(
      id: 'tattooist_$index',
      name: ['InkStudio', 'TattooArt', 'NeedleWork', 'BlackInk', 'InkMaster'][Random().nextInt(5)],
      avatarUrl: 'https://i.pravatar.cc/150?img=${Random().nextInt(70)}',
      coverImageUrl: 'https://picsum.photos/seed/${Random().nextInt(1000)}/800/400',
      location: ['Paris', 'Lyon', 'Marseille', 'Bordeaux', 'Lille'][Random().nextInt(5)],
      styles: List.generate(
        Random().nextInt(3) + 1,
        (i) => ['Traditionnel', 'Réaliste', 'Minimaliste', 'BlackWork', 'Géométrique'][Random().nextInt(5)],
      ),
      rating: 3.5 + Random().nextDouble() * 1.5,
      reviewsCount: Random().nextInt(100) + 5,
      isFavorite: Random().nextBool(),
    ),
  );

  Future<List<Tattooist>> getFavoriteTattooists() async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    
    return _mockTattooists.where((tattooist) => tattooist.isFavorite).toList();
  }

  Future<Tattooist> toggleFavorite(String tattooistId) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _mockTattooists.indexWhere((tattooist) => tattooist.id == tattooistId);
    if (index != -1) {
      final tattooist = _mockTattooists[index];
      final updatedTattooist = tattooist.copyWith(
        isFavorite: !tattooist.isFavorite,
      );
      _mockTattooists[index] = updatedTattooist;
      return updatedTattooist;
    }
    
    throw Exception('Tattooist not found');
  }
}