import 'package:flutter/material.dart';

class ZoneSelectionWidget extends StatefulWidget {
  final void Function(List<String>) onZonesSelected; // Callback pour récupérer les zones sélectionnées

  const ZoneSelectionWidget({super.key, required this.onZonesSelected});

  @override
  State<ZoneSelectionWidget> createState() => _ZoneSelectionWidgetState();
}

class _ZoneSelectionWidgetState extends State<ZoneSelectionWidget> {
  final List<String> _selectedZones = [];

  // Liste des zones disponibles et leurs positions approximatives
  final List<_Zone> _zones = [
    _Zone(name: 'Tête', top: 20, left: 130, width: 60, height: 60),
    _Zone(name: 'Torse', top: 90, left: 100, width: 120, height: 60),
    _Zone(name: 'Bas du ventre', top: 160, left: 100, width: 120, height: 50),
    _Zone(name: 'Bras gauche', top: 90, left: 40, width: 50, height: 140),
    _Zone(name: 'Bras droit', top: 90, left: 230, width: 50, height: 140),
    _Zone(name: 'Avant-bras gauche', top: 160, left: 40, width: 50, height: 70),
    _Zone(name: 'Avant-bras droit', top: 160, left: 230, width: 50, height: 70),
    _Zone(name: 'Jambe gauche', top: 220, left: 100, width: 50, height: 120),
    _Zone(name: 'Jambe droite', top: 220, left: 170, width: 50, height: 120),
    _Zone(name: 'Genou gauche', top: 270, left: 100, width: 50, height: 40),
    _Zone(name: 'Genou droit', top: 270, left: 170, width: 50, height: 40),
    _Zone(name: 'Dos haut', top: 90, left: 310, width: 120, height: 60),
    _Zone(name: 'Dos bas', top: 160, left: 310, width: 120, height: 70),
    _Zone(name: 'Fesses', top: 230, left: 310, width: 120, height: 50),
  ];

  void _toggleZone(String zoneName) {
    setState(() {
      if (_selectedZones.contains(zoneName)) {
        _selectedZones.remove(zoneName);
      } else {
        _selectedZones.add(zoneName);
      }
    });
    widget.onZonesSelected(_selectedZones);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/avatar_zones.png',
          fit: BoxFit.contain,
        ),
        ..._zones.map((zone) {
          final isSelected = _selectedZones.contains(zone.name);
          return Positioned(
            top: zone.top,
            left: zone.left,
            width: zone.width,
            height: zone.height,
            child: GestureDetector(
              onTap: () => _toggleZone(zone.name),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.red.withOpacity(0.4) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class _Zone {
  final String name;
  final double top;
  final double left;
  final double width;
  final double height;

  _Zone({required this.name, required this.top, required this.left, required this.width, required this.height});
}
