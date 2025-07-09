// lib/models/ai_action.dart

enum AIActionType {
  navigate,
  generateImage,
  openLink,
  contact,
  custom,
}

class AIAction {
  final AIActionType type;
  final String title;
  final String? subtitle;
  final String? route;
  final String? icon;
  final String? color;
  final Map<String, dynamic>? data;

  // ✅ AJOUTÉ: const constructor
  const AIAction({
    required this.type,
    required this.title,
    this.subtitle,
    this.route,
    this.icon,
    this.color,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'title': title,
      'subtitle': subtitle,
      'route': route,
      'icon': icon,
      'color': color,
      'data': data,
    };
  }

  factory AIAction.fromJson(Map<String, dynamic> json) {
    return AIAction(
      type: AIActionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AIActionType.custom,
      ),
      title: json['title'],
      subtitle: json['subtitle'],
      route: json['route'],
      icon: json['icon'],
      color: json['color'],
      data: json['data'],
    );
  }

  // ✅ Actions prédéfinies pour Kipik (maintenant utilisables avec const)
  static const AIAction searchTattooer = AIAction(
    type: AIActionType.navigate,
    title: '🔍 Rechercher un tatoueur',
    subtitle: 'Trouve le tatoueur parfait',
    route: '/recherche-tatoueur',
    icon: 'search',
    color: 'primary',
  );

  static const AIAction createProject = AIAction(
    type: AIActionType.navigate,
    title: '📝 Créer mon projet',
    subtitle: 'Démarrez votre tatouage',
    route: '/nouveau-projet',
    icon: 'add_circle',
    color: 'success',
  );

  static const AIAction viewGallery = AIAction(
    type: AIActionType.navigate,
    title: '🎨 Voir la galerie',
    subtitle: 'Inspirez-vous',
    route: '/galerie',
    icon: 'photo_library',
    color: 'purple',
  );

  static const AIAction estimatePrice = AIAction(
    type: AIActionType.navigate,
    title: '💰 Estimer le prix',
    subtitle: 'Calculez votre budget',
    route: '/estimateur',
    icon: 'calculate',
    color: 'orange',
  );

  static const AIAction tattooGuide = AIAction(
    type: AIActionType.navigate,
    title: '📚 Guide du tatouage',
    subtitle: 'Tout savoir sur les tatouages',
    route: '/guide',
    icon: 'menu_book',
    color: 'info',
  );

  static const AIAction generateImage = AIAction(
    type: AIActionType.generateImage,
    title: '🖼️ Générer une image',
    subtitle: 'Créez votre design',
    icon: 'image',
    color: 'gradient',
  );

  static const AIAction contactSupport = AIAction(
    type: AIActionType.contact,
    title: '💬 Contacter le support',
    subtitle: 'Besoin d\'aide ?',
    route: '/support',
    icon: 'support_agent',
    color: 'info',
  );
}