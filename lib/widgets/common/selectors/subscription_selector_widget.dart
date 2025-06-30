import 'package:flutter/material.dart';

class AbonnementOption {
  final String label;
  final String description;
  final double montantTTC;
  final String id;

  AbonnementOption({
    required this.label,
    required this.description,
    required this.montantTTC,
    required this.id,
  });
}

class AbonnementSelector extends StatelessWidget {
  final List<AbonnementOption> options;
  final String? selectedId;
  final Function(String) onSelected;

  const AbonnementSelector({
    super.key,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.map((option) {
        final isSelected = selectedId == option.id;
        return GestureDetector(
          onTap: () => onSelected(option.id),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              border: Border.all(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${option.montantTTC.toStringAsFixed(2)} € TTC',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                )
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
