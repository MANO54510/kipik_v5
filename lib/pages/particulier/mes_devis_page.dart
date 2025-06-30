// lib/pages/particulier/mes_devis_page.dart

import 'package:flutter/material.dart';
import '../../theme/kipik_theme.dart';
import 'detail_devis_page.dart';
import 'accueil_particulier_page.dart';
import '../../widgets/common/app_bars/custom_app_bar_particulier.dart'; // Ajout de l'import

enum StatutDevis { EnCours, Accepte, Refuse, Infos }

extension StatutDevisExtension on StatutDevis {
  String get label {
    switch (this) {
      case StatutDevis.EnCours:
        return 'En cours';
      case StatutDevis.Accepte:
        return 'Accepté';
      case StatutDevis.Refuse:
        return 'Refusé';
      case StatutDevis.Infos:
        return 'Infos manquantes';
    }
  }

  Color get color {
    switch (this) {
      case StatutDevis.EnCours:
        return KipikTheme.rouge;
      case StatutDevis.Accepte:
        return Colors.green;
      case StatutDevis.Refuse:
        return Colors.grey;
      case StatutDevis.Infos:
        return Colors.orange;
    }
  }
}

class Devis {
  final String userLastName;
  final String userFirstName;
  final String tattooerName;
  final String id;
  final DateTime date;
  final double montant;
  final StatutDevis statut;

  Devis({
    required this.userLastName,
    required this.userFirstName,
    required this.tattooerName,
    required this.id,
    required this.date,
    required this.montant,
    required this.statut,
  });
}

class MesDevisPage extends StatefulWidget {
  const MesDevisPage({Key? key}) : super(key: key);

  @override
  State<MesDevisPage> createState() => _MesDevisPageState();
}

class _MesDevisPageState extends State<MesDevisPage> {
  final List<Devis> _devisList = [
    Devis(
      userLastName: 'Dupont',
      userFirstName: 'Marie',
      tattooerName: 'InkMaster',
      id: 'D-001',
      date: DateTime(2024, 5, 1),
      montant: 120.0,
      statut: StatutDevis.EnCours,
    ),
    Devis(
      userLastName: 'Martin',
      userFirstName: 'Paul',
      tattooerName: 'Vintage Ink',
      id: 'D-002',
      date: DateTime(2024, 4, 28),
      montant: 80.0,
      statut: StatutDevis.Accepte,
    ),
    Devis(
      userLastName: 'Durand',
      userFirstName: 'Lucie',
      tattooerName: 'Mini Ink',
      id: 'D-003',
      date: DateTime(2024, 4, 25),
      montant: 200.0,
      statut: StatutDevis.Refuse,
    ),
    Devis(
      userLastName: 'Leroy',
      userFirstName: 'Sophie',
      tattooerName: 'InkMaster',
      id: 'D-004',
      date: DateTime(2024, 5, 3),
      montant: 150.0,
      statut: StatutDevis.Infos,
    ),
  ];

  // Ajout d'une variable pour stocker le filtre actuel
  StatutDevis? _selectedFilter;

  Map<StatutDevis, int> get _stats {
    final Map<StatutDevis, int> m = {};
    for (var s in StatutDevis.values) {
      m[s] = _devisList.where((d) => d.statut == s).length;
    }
    return m;
  }

  // Méthode pour obtenir la liste filtrée
  List<Devis> get _filteredDevisList {
    if (_selectedFilter == null) {
      return _devisList; // Retourner tous les devis si aucun filtre n'est sélectionné
    }
    return _devisList.where((d) => d.statut == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      backgroundColor: Colors.black,
      // Utilisation du CustomAppBarParticulier à la place de AppBar standard
      appBar: CustomAppBarParticulier(
        title: 'Mes devis',
        showBackButton: true,
        redirectToHome: true,
        showNotificationIcon: true, // Si vous souhaitez afficher l'icône de notification
      ),
      body: Column(
        children: [
          // Bandeau de résumé
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Chip pour "Total" - filtre par défaut
                _buildFilterChip('Total', _devisList.length, KipikTheme.rouge, null),
                // Chip pour chaque statut de devis
                for (var s in StatutDevis.values)
                  _buildFilterChip(s.label, stats[s]!, s.color, s),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          // Liste des devis filtrée
          Expanded(
            child: _filteredDevisList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Colors.white.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun devis ${_selectedFilter != null ? _selectedFilter!.label.toLowerCase() : ''} à afficher',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDevisList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final d = _filteredDevisList[i];
                      return Card(
                        color: Colors.white12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: d.statut.color, width: 2),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          title: Text(
                            '${d.userLastName}_${d.userFirstName} – ${d.tattooerName}',
                            style: const TextStyle(
                                color: Colors.white, fontFamily: 'PermanentMarker'),
                          ),
                          subtitle: Text(
                            'Le ${d.date.day}/${d.date.month}/${d.date.year} • ${d.montant.toStringAsFixed(2)} €',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: d.statut.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              d.statut.label,
                              style: TextStyle(
                                  color: d.statut.color,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => DetailDevisPage(devis: d)),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget pour créer une puce filtrable
  Widget _buildFilterChip(String label, int count, Color color, StatutDevis? statut) {
    final isSelected = (statut == _selectedFilter) || (statut == null && _selectedFilter == null);
    
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: color.withOpacity(0.2),
      selectedColor: color.withOpacity(0.4),
      label: Text(
        '$label : $count',
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      // Bordure visible uniquement pour le filtre sélectionné
      side: isSelected 
          ? BorderSide(color: color, width: 1.5) 
          : BorderSide(color: color.withOpacity(0.3), width: 1),
      onSelected: (selected) {
        setState(() {
          // Si on clique sur le filtre déjà sélectionné ou sur "Total", on désactive le filtre
          if ((statut == _selectedFilter) || statut == null) {
            _selectedFilter = null;
          } else {
            _selectedFilter = statut;
          }
        });
      },
    );
  }
}