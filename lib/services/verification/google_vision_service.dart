// lib/services/verification/google_vision_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import '../../services/config/api_config.dart';

class GoogleVisionService {
  
  /// Analyser un document avec Google Vision API
  static Future<DocumentAnalysisResult> analyzeDocument(XFile file) async {
    try {
      // Vérifier la configuration
      if (!(await ApiConfig.isGoogleVisionConfigured)) {
        throw Exception('Google Vision API non configurée');
      }
      
      print('🔍 Analyse du document avec Google Vision...');
      
      // 1. Lire et encoder le fichier
      final bytes = await file.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // 2. Préparer la requête avec plus de features pour une meilleure détection
      final request = {
        'requests': [
          {
            'image': {
              'content': base64Image,
            },
            'features': [
              {
                'type': 'DOCUMENT_TEXT_DETECTION',
                'maxResults': 50,
              },
              {
                'type': 'OBJECT_LOCALIZATION',
                'maxResults': 10,
              },
              // Ajout pour une meilleure détection des logos et éléments officiels
              {
                'type': 'LOGO_DETECTION',
                'maxResults': 5,
              },
            ],
          }
        ],
      };
      
      // 3. Appeler Google Vision API
      final apiKey = await ApiConfig.googleVisionApiKey;
      final response = await http.post(
        Uri.parse('${ApiConfig.googleVisionBaseUrl}/images:annotate?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Erreur Google Vision API: ${response.statusCode} - ${response.body}');
      }
      
      // 4. Parser la réponse
      final data = jsonDecode(response.body);
      final responses = data['responses'] as List;
      
      if (responses.isEmpty) {
        throw Exception('Aucune réponse de Google Vision');
      }
      
      final firstResponse = responses[0];
      
      // Vérifier les erreurs
      if (firstResponse['error'] != null) {
        throw Exception('Erreur API: ${firstResponse['error']['message']}');
      }
      
      // 5. Extraire les données
      final result = _parseVisionResponse(firstResponse, file.name, bytes.length);
      
      print('✅ Analyse terminée: ${result.documentType} (${result.confidence.toStringAsFixed(2)})');
      
      return result;
      
    } catch (e) {
      print('❌ Erreur analyse document: $e');
      return DocumentAnalysisResult.error(e.toString());
    }
  }
  
  /// Parser la réponse de Google Vision
  static DocumentAnalysisResult _parseVisionResponse(
    Map<String, dynamic> response, 
    String filename, 
    int fileSize,
  ) {
    // Extraire le texte
    String extractedText = '';
    if (response['fullTextAnnotation'] != null) {
      extractedText = response['fullTextAnnotation']['text'] ?? '';
    }
    
    // Analyser les objets détectés
    final objects = response['localizedObjectAnnotations'] as List? ?? [];
    final hasPhoto = objects.any((obj) => 
      ['Person', 'Face', 'Human face'].contains(obj['name']));
    
    // Analyser les logos détectés (pour documents officiels)
    final logos = response['logoAnnotations'] as List? ?? [];
    final hasOfficialLogo = logos.isNotEmpty;
    
    // Classifier le document selon les exigences KIPIK
    final classification = _classifyDocumentKIPIK(extractedText, filename, hasOfficialLogo);
    
    // Vérifications spécifiques
    final checks = _performKIPIKValidation(extractedText, filename, fileSize, classification.type);
    
    return DocumentAnalysisResult(
      documentType: classification.type,
      confidence: classification.confidence,
      extractedText: extractedText,
      hasPhoto: hasPhoto,
      hasSignature: _detectSignature(extractedText),
      fileSize: fileSize,
      language: _detectLanguage(extractedText),
      validationChecks: checks,
      recommendations: _generateKIPIKRecommendations(classification, checks),
      hasOfficialLogo: hasOfficialLogo,
    );
  }
  
  /// Classification optimisée pour les documents KIPIK
  static _DocumentType _classifyDocumentKIPIK(String text, String filename, bool hasOfficialLogo) {
    final normalizedText = text.toLowerCase().replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ');
    final normalizedFilename = filename.toLowerCase();
    
    // Patterns optimisés pour les documents requis par KIPIK
    final patterns = {
      // PIECES D'IDENTITÉ (Particuliers, Pro, Orga)
      'carte_identite': {
        'keywords': [
          'carte nationale d\'identité',
          'carte d\'identité',
          'république française',
          'nationalité française',
          'né(e) le',
          'préfecture',
          'ministère de l\'intérieur',
          'carte d\'identité française',
        ],
        'weight': 1.3,
        'required_count': 2, // Au moins 2 mots-clés requis
      },
      'passeport': {
        'keywords': [
          'passeport',
          'passport',
          'union européenne',
          'type p',
          'authority',
          'république française',
          'passeport français',
          'french passport',
        ],
        'weight': 1.3,
        'required_count': 2,
      },
      
      // DOCUMENTS FINANCIERS (Tous types)
      'rib': {
        'keywords': [
          'relevé d\'identité bancaire',
          'rib',
          'iban',
          'bic',
          'code banque',
          'domiciliation',
          'titulaire du compte',
          'établissement',
        ],
        'weight': 1.2,
        'required_count': 2,
      },
      
      // DOCUMENTS PROFESSIONNELS (Pro et Orga uniquement)
      'kbis': {
        'keywords': [
          'extrait kbis',
          'k-bis',
          'registre du commerce',
          'rcs',
          'siren',
          'siret',
          'greffe',
          'capital social',
          'extrait du registre',
        ],
        'weight': 1.4, // Poids élevé car très spécifique
        'required_count': 2,
      },
      'certificat_hygiene': {
        'keywords': [
          'certificat',
          'hygiène',
          'haccp',
          'formation',
          'salubrité',
          'agréé',
          'validité',
          'sécurité alimentaire',
        ],
        'weight': 1.1,
        'required_count': 2,
      },
    };
    
    double maxScore = 0.0;
    String bestType = 'unknown';
    
    patterns.forEach((type, config) {
      final keywords = config['keywords'] as List<String>;
      final weight = config['weight'] as double;
      final requiredCount = config['required_count'] as int;
      
      int matches = 0;
      List<String> foundKeywords = [];
      
      for (final keyword in keywords) {
        if (normalizedText.contains(keyword) || normalizedFilename.contains(keyword)) {
          matches++;
          foundKeywords.add(keyword);
        }
      }
      
      // Score uniquement si on a le nombre minimum de mots-clés
      if (matches >= requiredCount) {
        double score = (matches / keywords.length) * weight;
        
        // Bonus pour correspondance multiple
        if (matches > requiredCount) {
          score *= (1.0 + (matches - requiredCount) * 0.2);
        }
        
        // Bonus pour correspondance dans le nom de fichier
        bool filenameMatch = keywords.any((k) => normalizedFilename.contains(k));
        if (filenameMatch) {
          score *= 1.2;
        }
        
        if (score > maxScore) {
          maxScore = score;
          bestType = type;
        }
        
        print('🔍 Type: $type, Matches: $matches/${keywords.length}, Score: ${score.toStringAsFixed(2)}, Mots trouvés: $foundKeywords');
      }
    });
    
    return _DocumentType(
      type: bestType,
      confidence: maxScore.clamp(0.0, 1.0),
    );
  }
  
  /// Validations spécifiques KIPIK
  static List<ValidationCheck> _performKIPIKValidation(String text, String filename, int fileSize, String documentType) {
    final checks = <ValidationCheck>[];
    
    // 1. Vérifications générales
    _addGeneralChecks(checks, fileSize, filename, text);
    
    // 2. Vérifications spécifiques par type de document
    switch (documentType) {
      case 'carte_identite':
        _addIdentityCardChecks(checks, text);
        break;
      case 'passeport':
        _addPassportChecks(checks, text);
        break;
      case 'rib':
        _addRIBChecks(checks, text);
        break;
      case 'kbis':
        _addKbisChecks(checks, text);
        break;
      case 'certificat_hygiene':
        _addHygieneChecks(checks, text);
        break;
    }
    
    return checks;
  }
  
  static void _addGeneralChecks(List<ValidationCheck> checks, int fileSize, String filename, String text) {
    // Taille du fichier
    if (fileSize < 100 * 1024) { // Moins de 100KB
      checks.add(ValidationCheck('file_size', false, 'Fichier trop petit (${(fileSize/1024).round()}KB) - Qualité insuffisante'));
    } else if (fileSize > 15 * 1024 * 1024) { // Plus de 15MB
      checks.add(ValidationCheck('file_size', false, 'Fichier trop volumineux (${(fileSize/(1024*1024)).round()}MB)'));
    } else {
      checks.add(ValidationCheck('file_size', true, 'Taille acceptable (${(fileSize/1024).round()}KB)'));
    }
    
    // Format de fichier
    final validExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
    final extension = filename.split('.').last.toLowerCase();
    checks.add(ValidationCheck(
      'file_format', 
      validExtensions.contains(extension),
      validExtensions.contains(extension) ? 'Format valide: $extension' : 'Format non supporté: $extension',
    ));
    
    // Contenu textuel
    if (text.trim().isEmpty) {
      checks.add(ValidationCheck('text_content', false, 'Aucun texte détecté - Document illisible'));
    } else if (text.length < 30) {
      checks.add(ValidationCheck('text_content', false, 'Très peu de texte (${text.length} car.) - Qualité insuffisante'));
    } else {
      checks.add(ValidationCheck('text_content', true, 'Texte détecté (${text.length} caractères)'));
    }
  }
  
  static void _addIdentityCardChecks(List<ValidationCheck> checks, String text) {
    final normalizedText = text.toLowerCase();
    
    // Éléments obligatoires d'une CNI
    final requiredElements = {
      'nom': ['nom', 'surname'],
      'prenom': ['prénom', 'prénoms', 'given name'],
      'naissance': ['né(e) le', 'date of birth', 'birth'],
      'nationalite': ['nationalité', 'nationality', 'française'],
    };
    
    requiredElements.forEach((element, keywords) {
      bool found = keywords.any((k) => normalizedText.contains(k));
      checks.add(ValidationCheck(
        'cni_$element',
        found,
        found ? '✓ $element détecté' : '✗ $element manquant',
      ));
    });
  }
  
  // CORRECTION: Fonction _addPassportChecks corrigée
  static void _addPassportChecks(List<ValidationCheck> checks, String text) {
    final normalizedText = text.toLowerCase();
    
    // CORRECTION: Utiliser des listes cohérentes au lieu de types mixtes
    final typeKeywords = ['type p', 'passport'];
    final countryKeywords = ['fra', 'france'];
    final numeroRegex = RegExp(r'\d{2}[a-z]{2}\d{5}'); // Format numéro passeport français
    
    bool hasType = typeKeywords.any((k) => normalizedText.contains(k));
    bool hasCountry = countryKeywords.any((k) => normalizedText.contains(k));
    bool hasNumber = numeroRegex.hasMatch(text);
    
    checks.add(ValidationCheck('passport_type', hasType, hasType ? '✓ Type passeport détecté' : '✗ Type passeport manquant'));
    checks.add(ValidationCheck('passport_country', hasCountry, hasCountry ? '✓ Pays détecté' : '✗ Pays manquant'));
    checks.add(ValidationCheck('passport_number', hasNumber, hasNumber ? '✓ Numéro détecté' : '✗ Format numéro invalide'));
  }
  
  static void _addRIBChecks(List<ValidationCheck> checks, String text) {
    final normalizedText = text.toLowerCase();
    
    // Vérifications IBAN/BIC
    final ibanRegex = RegExp(r'fr\d{2}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{4}\s?\d{2}');
    final bicRegex = RegExp(r'[a-z]{4}fr[a-z0-9]{2}([a-z0-9]{3})?');
    
    bool hasIban = ibanRegex.hasMatch(normalizedText);
    bool hasBic = bicRegex.hasMatch(normalizedText) || normalizedText.contains('bic');
    bool hasTitulaire = normalizedText.contains('titulaire') || normalizedText.contains('account holder');
    
    checks.add(ValidationCheck('rib_iban', hasIban, hasIban ? '✓ IBAN français détecté' : '✗ IBAN manquant ou invalide'));
    checks.add(ValidationCheck('rib_bic', hasBic, hasBic ? '✓ BIC détecté' : '✗ BIC manquant'));
    checks.add(ValidationCheck('rib_titulaire', hasTitulaire, hasTitulaire ? '✓ Titulaire mentionné' : '✗ Titulaire non mentionné'));
  }
  
  static void _addKbisChecks(List<ValidationCheck> checks, String text) {
    final normalizedText = text.toLowerCase();
    
    // Vérifications spécifiques KBIS
    final sirenRegex = RegExp(r'\d{9}');
    final siretRegex = RegExp(r'\d{14}');
    
    bool hasSiren = normalizedText.contains('siren') && sirenRegex.hasMatch(text);
    bool hasSiret = normalizedText.contains('siret') && siretRegex.hasMatch(text);
    bool hasGreffe = normalizedText.contains('greffe');
    bool hasRCS = normalizedText.contains('rcs') || normalizedText.contains('registre du commerce');
    
    // Vérification de la date (KBIS de moins de 3 mois)
    bool hasRecentDate = _checkKbisDate(text);
    
    checks.add(ValidationCheck('kbis_siren', hasSiren, hasSiren ? '✓ SIREN détecté' : '✗ SIREN manquant'));
    checks.add(ValidationCheck('kbis_siret', hasSiret, hasSiret ? '✓ SIRET détecté' : '✗ SIRET manquant'));
    checks.add(ValidationCheck('kbis_greffe', hasGreffe, hasGreffe ? '✓ Greffe mentionné' : '✗ Greffe non mentionné'));
    checks.add(ValidationCheck('kbis_rcs', hasRCS, hasRCS ? '✓ RCS détecté' : '✗ RCS manquant'));
    checks.add(ValidationCheck('kbis_date', hasRecentDate, hasRecentDate ? '✓ Date récente' : '⚠️ Vérifier la date (< 3 mois requis)'));
  }
  
  static void _addHygieneChecks(List<ValidationCheck> checks, String text) {
    final normalizedText = text.toLowerCase();
    
    bool hasCertificat = normalizedText.contains('certificat');
    bool hasHygiene = normalizedText.contains('hygiène') || normalizedText.contains('haccp');
    bool hasValidite = normalizedText.contains('validité') || normalizedText.contains('valable');
    bool hasFormation = normalizedText.contains('formation') || normalizedText.contains('stage');
    
    checks.add(ValidationCheck('hygiene_certificat', hasCertificat, hasCertificat ? '✓ Certificat détecté' : '✗ Certificat non mentionné'));
    checks.add(ValidationCheck('hygiene_type', hasHygiene, hasHygiene ? '✓ Type hygiène détecté' : '✗ Type non précisé'));
    checks.add(ValidationCheck('hygiene_validite', hasValidite, hasValidite ? '✓ Validité mentionnée' : '⚠️ Vérifier la validité'));
    checks.add(ValidationCheck('hygiene_formation', hasFormation, hasFormation ? '✓ Formation mentionnée' : '✗ Formation non mentionnée'));
  }
  
  static bool _checkKbisDate(String text) {
    // Regex pour détecter des dates récentes (approximatif)
    final dateRegex = RegExp(r'\d{1,2}/\d{1,2}/202[4-5]');
    return dateRegex.hasMatch(text);
  }
  
  /// Détecter la présence d'une signature
  static bool _detectSignature(String text) {
    final signatureIndicators = [
      'signature',
      'signé',
      'signed',
      'le titulaire',
      'signature du titulaire',
      'certifié conforme',
    ];
    
    final normalizedText = text.toLowerCase();
    return signatureIndicators.any((indicator) => normalizedText.contains(indicator));
  }
  
  /// Détecter la langue
  static String _detectLanguage(String text) {
    final frenchWords = ['le', 'la', 'les', 'de', 'du', 'et', 'à', 'république', 'française', 'préfecture'];
    final normalizedText = text.toLowerCase();
    
    int frenchMatches = 0;
    for (final word in frenchWords) {
      if (normalizedText.contains(word)) {
        frenchMatches++;
      }
    }
    
    return frenchMatches >= 3 ? 'fr' : 'unknown';
  }
  
  /// Générer des recommandations KIPIK
  static List<String> _generateKIPIKRecommendations(_DocumentType classification, List<ValidationCheck> checks) {
    final recommendations = <String>[];
    
    // Recommandations selon la confiance
    if (classification.confidence > 0.8) {
      recommendations.add('✅ Document ${_getDocumentDisplayName(classification.type)} correctement identifié');
    } else if (classification.confidence > 0.5) {
      recommendations.add('⚠️ Document probablement un ${_getDocumentDisplayName(classification.type)} - Vérification manuelle recommandée');
    } else {
      recommendations.add('❌ Type de document incertain - Vérification manuelle obligatoire');
    }
    
    // Analyser les échecs de validation
    final failedChecks = checks.where((check) => !check.passed).toList();
    final criticalFailed = failedChecks.where((check) => 
      check.type.contains('_content') || 
      check.type.contains('_format') || 
      check.type.contains('_size')
    ).toList();
    
    if (criticalFailed.isNotEmpty) {
      recommendations.add('🚫 ${criticalFailed.length} vérification(s) critique(s) échouée(s)');
    } else if (failedChecks.isNotEmpty) {
      recommendations.add('⚠️ ${failedChecks.length} vérification(s) secondaire(s) à contrôler');
    }
    
    // Recommandations spécifiques par type
    _addTypeSpecificRecommendations(recommendations, classification.type, checks);
    
    return recommendations;
  }
  
  static void _addTypeSpecificRecommendations(List<String> recommendations, String type, List<ValidationCheck> checks) {
    switch (type) {
      case 'kbis':
        final dateCheck = checks.firstWhere((c) => c.type == 'kbis_date', orElse: () => ValidationCheck('', false, ''));
        if (!dateCheck.passed) {
          recommendations.add('📅 IMPORTANT: Vérifier que le KBIS date de moins de 3 mois');
        }
        break;
      case 'certificat_hygiene':
        recommendations.add('⏰ Vérifier la date de validité du certificat');
        break;
      case 'carte_identite':
      case 'passeport':
        recommendations.add('📸 Vérifier la présence de la photo et la lisibilité');
        break;
    }
  }
  
  static String _getDocumentDisplayName(String type) {
    const displayNames = {
      'carte_identite': 'Carte d\'identité',
      'passeport': 'Passeport',
      'rib': 'Relevé d\'identité bancaire (RIB)',
      'kbis': 'Extrait KBIS',
      'certificat_hygiene': 'Certificat d\'hygiène et salubrité',
      'unknown': 'Document non identifié',
    };
    return displayNames[type] ?? type;
  }
}

/// Résultat de l'analyse optimisé
class DocumentAnalysisResult {
  final String documentType;
  final double confidence;
  final String extractedText;
  final bool hasPhoto;
  final bool hasSignature;
  final int fileSize;
  final String language;
  final List<ValidationCheck> validationChecks;
  final List<String> recommendations;
  final bool isError;
  final String? errorMessage;
  final bool hasOfficialLogo;
  
  DocumentAnalysisResult({
    required this.documentType,
    required this.confidence,
    required this.extractedText,
    required this.hasPhoto,
    required this.hasSignature,
    required this.fileSize,
    required this.language,
    required this.validationChecks,
    required this.recommendations,
    this.isError = false,
    this.errorMessage,
    this.hasOfficialLogo = false,
  });
  
  factory DocumentAnalysisResult.error(String error) {
    return DocumentAnalysisResult(
      documentType: 'error',
      confidence: 0.0,
      extractedText: '',
      hasPhoto: false,
      hasSignature: false,
      fileSize: 0,
      language: 'unknown',
      validationChecks: [],
      recommendations: ['Erreur: $error'],
      isError: true,
      errorMessage: error,
    );
  }
  
  /// Action recommandée selon les critères KIPIK
  String get recommendedAction {
    if (isError) return 'ERROR';
    
    final criticalFailed = validationChecks.where((check) => 
      !check.passed && (
        check.type.contains('file_size') || 
        check.type.contains('file_format') || 
        check.type.contains('text_content')
      )
    ).toList();
    
    if (criticalFailed.isNotEmpty) {
      return 'REJECT';
    }
    
    if (confidence > 0.8 && validationChecks.where((c) => !c.passed).length <= 2) {
      return 'AUTO_APPROVE';
    } else if (confidence > 0.5) {
      return 'MANUAL_REVIEW';
    } else {
      return 'REJECT';
    }
  }
  
  /// Vérifier si le document est valide pour KIPIK
  bool get isValidForKIPIK {
    final validTypes = ['carte_identite', 'passeport', 'rib', 'kbis', 'certificat_hygiene'];
    return validTypes.contains(documentType) && confidence > 0.5;
  }
  
  /// Obtenir le nom d'affichage du document
  String get displayName {
    const displayNames = {
      'carte_identite': 'Carte d\'identité',
      'passeport': 'Passeport',
      'rib': 'RIB',
      'kbis': 'KBIS',
      'certificat_hygiene': 'Certificat d\'hygiène',
    };
    return displayNames[documentType] ?? 'Document non identifié';
  }
}

/// Check de validation
class ValidationCheck {
  final String type;
  final bool passed;
  final String message;
  
  ValidationCheck(this.type, this.passed, this.message);
  
  bool get isCritical => type.contains('file_') || type.contains('text_content');
}

/// Type de document détecté
class _DocumentType {
  final String type;
  final double confidence;
  
  _DocumentType({required this.type, required this.confidence});
}