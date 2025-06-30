// lib/pages/particulier/document_item.dart
import 'package:flutter/material.dart';

class DocumentItem extends StatelessWidget {
  final String fileName;
  final String type;
  final String date;
  final String? size;
  final bool? signed;
  final Color color;
  final IconData icon;
  final VoidCallback onView;
  final VoidCallback onDownload;

  const DocumentItem({
    Key? key,
    required this.fileName,
    required this.type,
    required this.date,
    this.size,
    this.signed,
    required this.color,
    required this.icon,
    required this.onView,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Vérifier que nous avons suffisamment d'espace
    final contentWidth = width - 64; // 32px de marge de container + 32px de marge de ListView

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: contentWidth,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        children: [
          // Pour éviter les problèmes de débordement, je vais limiter explicitement la largeur des éléments
          SizedBox(
            width: contentWidth,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Première ligne: icône et nom du fichier
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Nom du fichier (avec limitation de largeur)
                          Container(
                            width: contentWidth - 140, // 40px icône + 16px espace + 84px pour les marges et la bordure
                            child: Text(
                              fileName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'PermanentMarker',
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Type de document (couleur correspondante)
                      Container(
                        width: contentWidth - 32, // Marge de padding
                        child: Text(
                          type.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Date et taille (si disponible)
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.white54, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            date,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          
                          if (size != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.data_usage, color: Colors.white54, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              size!,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Badge SIGNÉ (si applicable)
                      if (signed != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: signed! ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            signed! ? 'SIGNÉ' : 'NON SIGNÉ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Boutons d'action (à droite)
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Bouton visualiser
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.white),
                        onPressed: onView,
                      ),
                      
                      // Bouton télécharger
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.white),
                        onPressed: onDownload,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}