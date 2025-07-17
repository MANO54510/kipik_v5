// lib/core/helpers/widget_helper.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/kipik_theme.dart';
import 'service_helper.dart';

/// 🎯 Helper central pour tous les widgets récurrents
/// Évite la duplication de code UI dans toute l'app
class WidgetHelper {
  
  // 🎨 HEADERS STANDARDISÉS
  static Widget buildStepHeader(String title, String subtitle, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [KipikTheme.rouge, KipikTheme.rouge.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: KipikTheme.titleStyle.copyWith(fontSize: 18)),
                const SizedBox(height: 4),
                Text(subtitle, style: KipikTheme.bodyTextSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📊 CARTES DE STATS STANDARDISÉES
  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? backgroundColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: KipikTheme.rouge, size: 32),
            const SizedBox(height: 8),
            Text(value, style: KipikTheme.cardTitleStyle.copyWith(color: Colors.black87)),
            Text(title, style: KipikTheme.bodyTextStyle.copyWith(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // 📝 CHAMPS DE FORMULAIRE STANDARDISÉS
  static Widget buildFormField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffix,
    bool obscureText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KipikTheme.bodyTextStyle.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white.withOpacity(0.95),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            suffixIcon: suffix,
          ),
          maxLines: obscureText ? 1 : maxLines,
          keyboardType: keyboardType,
          validator: validator,
        ),
      ],
    );
  }

  // 📅 SÉLECTEURS DE DATE/HEURE
  static Widget buildDateCard(
    String label,
    DateTime? date,
    Function(DateTime) onDateSelected,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, color: KipikTheme.rouge, size: 20),
                const SizedBox(width: 8),
                Text(
                  date != null
                      ? ServiceHelper.formatDate(date)
                      : 'Sélectionner',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: date != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTimeCard(
    String label,
    TimeOfDay? time,
    Function(TimeOfDay) onTimeSelected,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () async {
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: time ?? const TimeOfDay(hour: 10, minute: 0),
        );
        if (selectedTime != null) {
          onTimeSelected(selectedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: KipikTheme.rouge, size: 20),
                const SizedBox(width: 8),
                Text(
                  time != null
                      ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                      : 'Sélectionner',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: time != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 SÉLECTEUR DE TYPE
  static Widget buildTypeSelector<T>({
    required String label,
    required List<T> options,
    required T selectedValue,
    required String Function(T) getLabel,
    required IconData Function(T) getIcon,
    required void Function(T) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? KipikTheme.rouge : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getIcon(option),
                      size: 20,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getLabel(option),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 🎯 ONGLETS STANDARDISÉS
  static Widget buildTabBar({
    required List<String> tabs,
    required int selectedIndex,
    required void Function(int) onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KipikTheme.rouge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = selectedIndex == index;
          
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? KipikTheme.rouge : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: KipikTheme.fontTitle,
                    fontSize: 11,
                    color: isSelected ? Colors.white : KipikTheme.rouge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 🎚️ SLIDER AVEC VALEUR
  static Widget buildSliderSetting({
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required String displayValue,
    BuildContext? context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: KipikTheme.rouge.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayValue,
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 12,
                  color: KipikTheme.rouge,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: context != null 
              ? SliderTheme.of(context).copyWith(
                  activeTrackColor: KipikTheme.rouge,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: KipikTheme.rouge,
                  overlayColor: KipikTheme.rouge.withOpacity(0.2),
                )
              : SliderThemeData(
                  activeTrackColor: KipikTheme.rouge,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: KipikTheme.rouge,
                  overlayColor: KipikTheme.rouge.withOpacity(0.2),
                ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 10).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // 💳 SÉLECTEUR D'AMÉNITÉS
  static Widget buildAmenitiesSelector({
    required List<String> selectedAmenities,
    required void Function(List<String>) onChanged,
  }) {
    final amenities = [
      {'id': 'wifi', 'label': 'WiFi gratuit', 'icon': Icons.wifi},
      {'id': 'parking', 'label': 'Parking', 'icon': Icons.local_parking},
      {'id': 'food', 'label': 'Restauration', 'icon': Icons.restaurant},
      {'id': 'security', 'label': 'Sécurité', 'icon': Icons.security},
      {'id': 'sound', 'label': 'Sonorisation', 'icon': Icons.volume_up},
      {'id': 'lighting', 'label': 'Éclairage pro', 'icon': Icons.lightbulb},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: KipikTheme.rouge, size: 24),
              const SizedBox(width: 12),
              Text(
                'Services et Équipements',
                style: TextStyle(
                  fontFamily: KipikTheme.fontTitle,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: amenities.map((amenity) {
              final isSelected = selectedAmenities.contains(amenity['id']);
              return GestureDetector(
                onTap: () {
                  final newList = List<String>.from(selectedAmenities);
                  if (isSelected) {
                    newList.remove(amenity['id']);
                  } else {
                    newList.add(amenity['id'] as String);
                  }
                  onChanged(newList);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? KipikTheme.rouge.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? KipikTheme.rouge : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        amenity['icon'] as IconData,
                        size: 16,
                        color: isSelected ? KipikTheme.rouge : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        amenity['label'] as String,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? KipikTheme.rouge : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 📱 STREAM BUILDER OPTIMISÉ
  static Widget buildStreamWidget<T>({
    required Stream<T> stream,
    required Widget Function(T data) builder,
    Widget? loading,
    Widget Function(String error)? error,
    Widget? empty,
  }) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? Center(child: KipikTheme.loading());
        }

        if (snapshot.hasError) {
          return error?.call(snapshot.error.toString()) ?? 
            KipikTheme.errorState(
              title: 'Erreur de chargement',
              message: snapshot.error.toString(),
            );
        }

        if (!snapshot.hasData) {
          return empty ?? KipikTheme.emptyState(
            icon: Icons.inbox,
            title: 'Aucune donnée',
            message: 'Aucune information disponible',
          );
        }

        return builder(snapshot.data!);
      },
    );
  }

  // 🎯 FUTURE BUILDER OPTIMISÉ
  static Widget buildFutureWidget<T>({
    required Future<T> future,
    required Widget Function(T data) builder,
    Widget? loading,
    Widget Function(String error)? error,
  }) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loading ?? Center(child: KipikTheme.loading());
        }

        if (snapshot.hasError) {
          return error?.call(snapshot.error.toString()) ?? 
            KipikTheme.errorState(
              title: 'Erreur',
              message: snapshot.error.toString(),
            );
        }

        if (!snapshot.hasData) {
          return KipikTheme.emptyState(
            icon: Icons.inbox,
            title: 'Aucune donnée',
            message: 'Aucune information disponible',
          );
        }

        return builder(snapshot.data!);
      },
    );
  }

  // 📊 LISTE D'ÉLÉMENTS AVEC ACTIONS
  static Widget buildListItem({
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget>? actions,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KipikTheme.cardTitleStyle.copyWith(color: Colors.black87)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: KipikTheme.bodyTextStyle.copyWith(color: Colors.grey, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (actions != null) ...actions,
          ],
        ),
      ),
    );
  }

  // 💰 AFFICHAGE DE REVENUS
  static Widget buildRevenueCard({
    required String title,
    required double amount,
    double? growth,
    Color? backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: KipikTheme.bodyTextStyle.copyWith(color: Colors.black87)),
          const SizedBox(height: 8),
          Text(
            ServiceHelper.formatCurrency(amount),
            style: KipikTheme.titleStyle.copyWith(color: Colors.green[700], fontSize: 24),
          ),
          if (growth != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  growth >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: growth >= 0 ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${growth.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: growth >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🎨 BADGES DE STATUT (CORRIGÉ)
  static Widget buildStatusBadge(String status) {
    final color = KipikTheme.getStatusColor(status);
    final lightColor = KipikTheme.getStatusColorShade(status, 100);
    final borderColor = KipikTheme.getStatusColorShade(status, 300);
    final textColor = KipikTheme.getStatusColorShade(status, 700);
    
    String label;
    switch (status.toLowerCase()) {
      case 'active':
      case 'published':
      case 'confirmed':
        label = 'Actif';
        break;
      case 'pending':
        label = 'En attente';
        break;
      case 'draft':
        label = 'Brouillon';
        break;
      case 'cancelled':
      case 'rejected':
        label = 'Annulé';
        break;
      default:
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: KipikTheme.fontTitle,
        ),
      ),
    );
  }

  // 🔄 INDICATEUR DE PROGRESSION
  static Widget buildProgressIndicator({
    required int currentStep,
    required int totalSteps,
    required String stepTitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Étape $currentStep/$totalSteps', style: KipikTheme.bodyTextStyle.copyWith(color: Colors.black87)),
              Text(stepTitle, style: KipikTheme.bodyTextStyle.copyWith(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(KipikTheme.rouge),
          ),
        ],
      ),
    );
  }

  // 🎯 BOUTONS D'ACTION RAPIDES
  static Widget buildActionButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    bool isLoading = false,
    IconData? icon,
    double? width,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (icon != null ? Icon(icon, size: 16) : const SizedBox.shrink()),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? KipikTheme.rouge : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // 📝 RÉSUMÉ RÉCAPITULATIF
  static Widget buildSummaryCard({
    required Map<String, String> summaryData,
    String? title,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Icon(Icons.summarize, color: KipikTheme.rouge, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: KipikTheme.fontTitle,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          
          ...summaryData.entries.map((entry) => 
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value.isNotEmpty ? entry.value : 'Non renseigné',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: entry.value.isNotEmpty ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔄 SWITCH AVEC TITRE
  static Widget buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: KipikTheme.rouge,
    );
  }

  // 🎨 CONTAINER AVEC STYLE KIPIK
  static Widget buildKipikContainer({
    required Widget child,
    EdgeInsets? padding,
    Color? backgroundColor,
    double borderRadius = 16,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}