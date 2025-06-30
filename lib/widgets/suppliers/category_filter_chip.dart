import 'package:flutter/material.dart';
import 'package:kipik_v5/models/category.dart' as CategoryModel; // ✅ Import avec alias

class CategoryFilterChip extends StatelessWidget {
  final CategoryModel.Category category; // ✅ Utilisation de l'alias
  final bool isSelected;
  final Function(bool) onSelected;
  final bool showIcon;
  final bool showCount;
  final EdgeInsets padding;
  final double fontSize;
  final bool showBorder;

  const CategoryFilterChip({
    Key? key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
    this.showIcon = true,
    this.showCount = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.fontSize = 14,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // ✅ Couleur d'accent définie localement ou récupérée du thème
    final accentColor = theme.colorScheme.primary;
    
    return GestureDetector(
      onTap: () => onSelected(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), // ✅ const ajouté
        padding: padding,
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: showBorder
              ? Border.all(
                  color: isSelected ? accentColor : Colors.grey[300]!,
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon && category.iconData != null) ...[
              Icon(
                category.iconData,
                size: fontSize + 2,
                color: isSelected ? accentColor : Colors.grey[600],
              ),
              const SizedBox(width: 6), // ✅ const ajouté
            ],
            Text(
              category.name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accentColor : Colors.grey[800],
              ),
            ),
            if (showCount && category.itemCount > 0) ...[
              const SizedBox(width: 4), // ✅ const ajouté
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // ✅ const ajouté
                decoration: BoxDecoration(
                  color: isSelected 
                      ? accentColor 
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${category.itemCount}',
                  style: TextStyle(
                    fontSize: fontSize - 2,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CategoryFilterChipGroup extends StatelessWidget {
  final List<CategoryModel.Category> categories; // ✅ Utilisation de l'alias
  final List<String> selectedCategoryIds;
  final Function(String, bool) onCategorySelected;
  final bool scrollable;
  final MainAxisAlignment alignment;
  final bool showIcon;
  final bool showCount;
  final bool allowMultipleSelection;
  final double spacing;
  final double chipHeight;
  final double fontSize;
  final bool showBorder;

  const CategoryFilterChipGroup({
    Key? key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategorySelected,
    this.scrollable = true,
    this.alignment = MainAxisAlignment.start,
    this.showIcon = true,
    this.showCount = true,
    this.allowMultipleSelection = true,
    this.spacing = 8.0,
    this.chipHeight = 36.0,
    this.fontSize = 14.0,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (scrollable) {
      return SizedBox(
        height: chipHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16), // ✅ const ajouté
          separatorBuilder: (context, index) => SizedBox(width: spacing),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = selectedCategoryIds.contains(category.id);
            
            return CategoryFilterChip(
              category: category,
              isSelected: isSelected,
              onSelected: (selected) {
                if (!allowMultipleSelection && selected) {
                  // Si la sélection multiple n'est pas autorisée, désélectionner les autres
                  for (var cat in categories) {
                    if (cat.id != category.id && selectedCategoryIds.contains(cat.id)) {
                      onCategorySelected(cat.id, false);
                    }
                  }
                }
                onCategorySelected(category.id, selected);
              },
              showIcon: showIcon,
              showCount: showCount,
              fontSize: fontSize,
              showBorder: showBorder,
            );
          },
        ),
      );
    } else {
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        alignment: WrapAlignment.start,
        children: categories.map((category) {
          final isSelected = selectedCategoryIds.contains(category.id);
          
          return CategoryFilterChip(
            category: category,
            isSelected: isSelected,
            onSelected: (selected) {
              if (!allowMultipleSelection && selected) {
                // Si la sélection multiple n'est pas autorisée, désélectionner les autres
                for (var cat in categories) {
                  if (cat.id != category.id && selectedCategoryIds.contains(cat.id)) {
                    onCategorySelected(cat.id, false);
                  }
                }
              }
              onCategorySelected(category.id, selected);
            },
            showIcon: showIcon,
            showCount: showCount,
            fontSize: fontSize,
            showBorder: showBorder,
          );
        }).toList(),
      );
    }
  }
}