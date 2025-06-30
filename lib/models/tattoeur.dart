// lib/models/tattoeur.dart
class Tatoueur {
  final String name;
  final String style;
  final double lat;
  final double lng;
  final String avail;
  final String avatar;
  final String bannerAsset;
  final String bio;

  Tatoueur({
    required this.name,
    required this.style,
    required this.lat,
    required this.lng,
    required this.avail,
    required this.avatar,
    required this.bannerAsset,
    required this.bio,
  });

  factory Tatoueur.fromMap(Map<String, dynamic> m) => Tatoueur(
        name: m['name'] as String,
        style: m['style'] as String,
        lat: m['lat'] as double,
        lng: m['lng'] as double,
        avail: m['avail'] as String,
        avatar: m['avatar'] as String,
        bannerAsset: m['bannerAsset'] as String? ?? 'assets/banniere_kipik.jpg',
        bio: m['bio'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'style': style,
        'lat': lat,
        'lng': lng,
        'avail': avail,
        'avatar': avatar,
        'bannerAsset': bannerAsset,
        'bio': bio,
      };
}
