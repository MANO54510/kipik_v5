// lib/pages/particulier/document_card_widget.dart

import 'package:flutter/material.dart';

class DocumentCard extends StatelessWidget {
  final String title;
  final String type;
  final String date;
  final String? size;
  final bool? isSigned;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback onView;
  final VoidCallback onDownload;

  const DocumentCard({
    Key? key,
    required this.title,
    required this.type,
    required this.date,
    this.size,
    this.isSigned,
    required this.iconData,
    required this.iconColor,
    required this.onView,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculer la largeur maximale disponible
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth - 64; // 32px pour les marges de la carte + 32px pour les marges de la liste
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withOpacity(0.6), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onView,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1: Icône et titre
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône du document dans un cercle coloré
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: iconColor,
                          size: 20,
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Titre du document (avec largeur limitée)
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'PermanentMarker',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Ligne 2: Type de document
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Ligne 3: Date et taille
                  Row(
                    children: [
                      // Date
                      const Icon(Icons.calendar_today, color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      
                      // Taille (si disponible)
                      if (size != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.data_usage, color: Colors.white54, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            size!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Ligne 4: Badge "Signé" et boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge "Signé" ou "Non signé" (si applicable)
                      if (isSigned != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSigned! ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            isSigned! ? 'SIGNÉ' : 'NON SIGNÉ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // Boutons d'action
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Bouton Visualiser
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.white),
                            onPressed: onView,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                          ),
                          const SizedBox(width: 12),
                          // Bouton Télécharger
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white),
                            onPressed: onDownload,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}