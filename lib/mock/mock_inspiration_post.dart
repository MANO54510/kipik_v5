// lib/mock/mock_inspiration_post.dart
import '../models/inspiration_post.dart';

final InspirationPost mockInspirationPost = InspirationPost(
  id: 'inspiration_1',
  title: 'Tattoo test',
  description: 'Super idée à tester pour ton routing',
  imageUrl: 'https://dummyimage.com/600x400',
  additionalImages: const [],
  authorId: 'user_1',
  authorName: 'Jane Doe',
  authorAvatarUrl: 'https://dummyimage.com/100x100',
  isFromProfessional: true,
  likes: 42,
  views: 100,
  tags: ['fleur', 'noir-et-gris'],
  tattooPlacements: ['avant-bras', 'épaule'],
  tattooStyles: ['réalisme', 'fineline'],
  isFavorite: false,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(), // OBLIGATOIRE pour la nouvelle version du modèle
);
