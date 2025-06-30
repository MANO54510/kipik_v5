import 'package:flutter/material.dart';

class CGUCGVValidationWidget extends StatelessWidget {
  final bool cguAccepted;
  final bool cgvAccepted;
  final VoidCallback onCGURead;
  final VoidCallback onCGVRead;

  const CGUCGVValidationWidget({
    super.key,
    required this.cguAccepted,
    required this.cgvAccepted,
    required this.onCGURead,
    required this.onCGVRead,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text("Lire les CGU", style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: onCGURead,
        ),
        CheckboxListTile(
          value: cguAccepted,
          onChanged: null, // Désactivé car le clic ne doit pas cocher sans lecture
          title: const Text("J'accepte les CGU", style: TextStyle(color: Colors.white)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text("Lire les CGV", style: TextStyle(color: Colors.white)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onTap: onCGVRead,
        ),
        CheckboxListTile(
          value: cgvAccepted,
          onChanged: null, // Désactivé car le clic ne doit pas cocher sans lecture
          title: const Text("J'accepte les CGV", style: TextStyle(color: Colors.white)),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}