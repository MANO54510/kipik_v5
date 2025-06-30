// lib/models/facture.dart

class Facture {
  final String numeroFacture;
  final String dateEmission;
  final String tatoueurNom;
  final String tatoueurSiret;
  final String tatoueurAdresse;
  final String tatoueurEmail;
  final String tatoueurTelephone;
  final String clientNom;
  final String clientAdresse;
  final String clientEmail;
  final String projetTitre;
  final String dateRealisation;
  final List<FactureItem> items;
  final double totalHT;
  final double tva;
  final double totalTTC;
  final String mentionsLegales;
  final String modePaiement;
  final bool acquitte;

  Facture({
    required this.numeroFacture,
    required this.dateEmission, 
    required this.tatoueurNom,
    required this.tatoueurSiret,
    required this.tatoueurAdresse,
    required this.tatoueurEmail,
    required this.tatoueurTelephone,
    required this.clientNom,
    required this.clientAdresse,
    required this.clientEmail,
    required this.projetTitre,
    required this.dateRealisation,
    required this.items,
    required this.totalHT,
    required this.tva,
    required this.totalTTC,
    required this.mentionsLegales,
    required this.modePaiement,
    this.acquitte = false,
  });

  // Méthode pour générer une facture à partir des données du projet
  static Facture genererDepuisProjet(Map<String, dynamic> projet, String clientNom, String clientAdresse, String clientEmail) {
    final maintenant = DateTime.now();
    final numeroFacture = 'FACT-${maintenant.year}${maintenant.month.toString().padLeft(2, '0')}${maintenant.day.toString().padLeft(2, '0')}-${projet['id']}';
    
    final items = <FactureItem>[
      FactureItem(
        description: 'Tatouage: ${projet['titre']}',
        quantite: 1,
        prixUnitaire: double.parse(projet['montantFinal'].replaceAll('€', '')),
      ),
    ];
    
    // Calculer les totaux
    final totalHT = items.fold(0.0, (total, item) => total + item.total);
    const tva = 0.0; // Généralement, les tatouages sont exonérés de TVA
    final totalTTC = totalHT + tva;
    
    return Facture(
      numeroFacture: numeroFacture,
      dateEmission: '${maintenant.day.toString().padLeft(2, '0')}/${maintenant.month.toString().padLeft(2, '0')}/${maintenant.year}',
      tatoueurNom: projet['tatoueur'],
      tatoueurSiret: '123 456 789 00012', // À remplacer par le vrai SIRET
      tatoueurAdresse: '15 Rue de la Création, 75011 Paris', // À remplacer
      tatoueurEmail: 'contact@studio.com', // À remplacer
      tatoueurTelephone: '01 23 45 67 89', // À remplacer
      clientNom: clientNom,
      clientAdresse: clientAdresse,
      clientEmail: clientEmail,
      projetTitre: projet['titre'],
      dateRealisation: projet['date_fin'],
      items: items,
      totalHT: totalHT,
      tva: tva,
      totalTTC: totalTTC,
      mentionsLegales: '''
Conformément à l'article 293 B du Code Général des Impôts, TVA non applicable.
Délai de paiement : paiement à réception de facture.
En cas de retard de paiement, indemnité forfaitaire de 40€ pour frais de recouvrement (art. L441-6 et D441-5 du code de commerce).
      ''',
      modePaiement: 'Espèces', // À personnaliser
      acquitte: true,
    );
  }
}

class FactureItem {
  final String description;
  final int quantite;
  final double prixUnitaire;
  
  FactureItem({
    required this.description,
    required this.quantite,
    required this.prixUnitaire,
  });
  
  double get total => quantite * prixUnitaire;
}