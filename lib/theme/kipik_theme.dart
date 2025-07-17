// lib/theme/kipik_theme.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';

/// 🎨 KipikTheme - UNIQUEMENT pour l'apparence visuelle
/// ✅ MISE À JOUR COMPLÈTE avec toutes les méthodes nécessaires
class KipikTheme {
  
  // ===============================================
  // ✅ COULEURS ET STYLES (INCHANGÉ)
  // ===============================================
  
  static const Color noir = Colors.black;
  static const Color blanc = Colors.white;
  static const Color rouge = Color.fromARGB(255, 134, 7, 7);
  static const String fontTitle = 'PermanentMarker';

  // Couleurs dérivées
  static Color get rougeLight => rouge.withOpacity(0.85);
  static Color get blancTransparent => blanc.withOpacity(0.7);
  static Color get noirTransparent => noir.withOpacity(0.8);

  // ===============================================
  // ✅ BACKGROUNDS (INCHANGÉ)
  // ===============================================
  
  static const List<String> backgrounds = [
    'assets/background1.png',
    'assets/background2.png',
    'assets/background3.png',
    'assets/background4.png',
  ];

  static String getRandomBackground() {
    return backgrounds[Random().nextInt(backgrounds.length)];
  }

  // ===============================================
  // ✅ FORMATAGE DE DATE (NOUVEAU)
  // ===============================================
  
  /// Retourne une date formatée lisible
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // ===============================================
  // ✅ SCAFFOLDS - MISE À JOUR RÉTRO-COMPATIBLE
  // ===============================================
  
  static Widget scaffoldWithBackground({
    required Widget child,
    PreferredSizeWidget? appBar,
    Widget? drawer,
    Widget? endDrawer,
    Widget? floatingActionButton,
    FloatingActionButtonLocation? floatingActionButtonLocation,
    String? specificBackground,
    bool extendBodyBehindAppBar = true,
    bool? resizeToAvoidBottomInset,
    Widget? bottomNavigationBar,
    Widget? bottomSheet,
    Color? backgroundColor,
    bool primary = true,
    DragStartBehavior drawerDragStartBehavior = DragStartBehavior.start,
    bool extendBody = false,
    List<Widget>? persistentFooterButtons,
    AlignmentDirectional persistentFooterAlignment = AlignmentDirectional.centerEnd,
  }) {
    final bgAsset = specificBackground ?? getRandomBackground();
    
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      primary: primary,
      drawerDragStartBehavior: drawerDragStartBehavior,
      extendBody: extendBody,
      persistentFooterButtons: persistentFooterButtons,
      persistentFooterAlignment: persistentFooterAlignment,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            bgAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: noir);
            },
          ),
          child,
        ],
      ),
    );
  }

  static Widget scaffoldWithoutBackground({
    required Widget child,
    PreferredSizeWidget? appBar,
    Widget? drawer,
    Widget? endDrawer,
    Widget? floatingActionButton,
    Color? backgroundColor,
  }) {
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      backgroundColor: backgroundColor ?? noir,
      body: child,
    );
  }

  static Widget withSpecificBackground(
    String backgroundAsset, {
    required Widget child,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          backgroundAsset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: noir);
          },
        ),
        child,
      ],
    );
  }

  // ===============================================
  // ✅ MÉTHODE pageContent
  // ===============================================
  
  static Widget pageContent({
    Widget? child,
    List<Widget>? children,
    EdgeInsets? padding,
    bool scrollable = false,
    ScrollController? scrollController,
  }) {
    assert(
      (child != null) ^ (children != null),
      'Vous devez fournir soit child, soit children, mais pas les deux',
    );

    Widget content;
    if (children != null) {
      content = Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      );
    } else {
      content = Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child!,
      );
    }

    if (scrollable) {
      return SingleChildScrollView(
        controller: scrollController,
        child: content,
      );
    }

    return content;
  }

  // ===============================================
  // ✅ STYLES DE TEXTE (INCHANGÉ)
  // ===============================================
  
  static const TextStyle titleStyle = TextStyle(
    fontFamily: fontTitle,
    fontSize: 26,
    color: blanc,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontFamily: fontTitle,
    fontSize: 16,
    color: blanc,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontFamily: fontTitle,
    fontSize: 18,
    color: blanc,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    color: blanc,
  );

  static TextStyle get bodyTextSecondary => TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    color: blanc.withOpacity(0.7),
  );

  // ===============================================
  // ✅ COMPOSANTS VISUELS SIMPLES
  // ===============================================
  
  static Widget loading({Color? color}) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color ?? rouge),
    );
  }

  static Widget loadingWhite() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(blanc),
    );
  }

  // ===============================================
  // ✅ MÉTHODE card - NOUVELLE
  // ===============================================
  
  static Widget card({
    Widget? child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    VoidCallback? onTap,
  }) {
    Widget container = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        border: borderColor != null || borderWidth != null
            ? Border.all(
                color: borderColor ?? Colors.grey.shade300,
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          child: container,
        ),
      );
    }

    return container;
  }

  // ===============================================
  // ✅ BOUTONS - NOUVELLES MÉTHODES
  // ===============================================
  
  static Widget primaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool enabled = true,
    EdgeInsets? padding,
    double? fontSize,
  }) {
    return ElevatedButton(
      onPressed: enabled && !isLoading ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: rouge,
        foregroundColor: blanc,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: blanc,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  static Widget secondaryButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isLoading = false,
    bool enabled = true,
    EdgeInsets? padding,
    double? fontSize,
  }) {
    return OutlinedButton(
      onPressed: enabled && !isLoading ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: rouge,
        side: BorderSide(color: rouge),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: rouge,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  // ===============================================
  // ✅ MÉTHODE demoBadge
  // ===============================================
  
  static Widget demoBadge({
    String? text,
    String? customText,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    double? fontSize,
  }) {
    final displayText = customText ?? text ?? 'Badge';
    
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? rouge,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontFamily: fontTitle,
          fontSize: fontSize ?? 12,
          color: textColor ?? blanc,
        ),
      ),
    );
  }

  // ===============================================
  // ✅ MÉTHODE searchField
  // ===============================================
  
  static Widget searchField({
    required TextEditingController controller,
    String? hintText,
    ValueChanged<String>? onChanged,
    VoidCallback? onClear,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    Color? backgroundColor,
    Color? textColor,
    TextStyle? hintStyle,
    InputBorder? border,
    EdgeInsets? contentPadding,
  }) {
    final effectiveFillColor = backgroundColor ?? fillColor ?? blanc.withOpacity(0.1);
    
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        color: textColor ?? blanc,
      ),
      decoration: InputDecoration(
        hintText: hintText ?? 'Rechercher...',
        hintStyle: hintStyle ?? TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: (textColor ?? blanc).withOpacity(0.5),
        ),
        filled: true,
        fillColor: effectiveFillColor,
        border: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: border ?? OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: rouge, width: 1),
        ),
        contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        prefixIcon: prefixIcon ?? Icon(Icons.search, color: (textColor ?? blanc).withOpacity(0.7)),
        suffixIcon: suffixIcon ?? (controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: (textColor ?? blanc).withOpacity(0.7)),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                  onChanged?.call('');
                },
              )
            : null),
      ),
    );
  }

  // ===============================================
  // ✅ ÉTATS VISUELS
  // ===============================================
  
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String message,
    Color? iconColor,
    Widget? action,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: iconColor ?? blanc),
            const SizedBox(height: 16),
            Text(title, style: titleStyle.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: bodyTextSecondary),
            if (action != null) ...[
              const SizedBox(height: 16),
              action,
            ],
          ],
        ),
      ),
    );
  }

  static Widget errorState({
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    return emptyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      iconColor: Colors.red,
      action: onRetry != null
          ? ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: blanc,
              ),
              child: const Text('Réessayer'),
            )
          : null,
    );
  }

  // ===============================================
  // ✅ SNACKBARS
  // ===============================================
  
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: fontTitle)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Roboto')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Roboto')),
        backgroundColor: rouge,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ===============================================
  // ✅ DIALOGUES - NOUVELLE MÉTHODE
  // ===============================================
  
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: fontTitle,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? rouge,
              foregroundColor: blanc,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  // ===============================================
  // ✅ THEMEDATA
  // ===============================================
  
  static ThemeData get themeData => ThemeData(
    primaryColor: noir,
    scaffoldBackgroundColor: noir,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: noir,
      centerTitle: true,
      iconTheme: IconThemeData(color: blanc),
      titleTextStyle: TextStyle(
        fontFamily: fontTitle,
        color: blanc,
        fontSize: 22,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: blanc),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: rouge,
      brightness: Brightness.dark,
    ),
  );

  // ===============================================
  // ✅ COULEURS POUR WIDGETS
  // ===============================================
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'published':
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      case 'finished':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static Color getStatusColorShade(String status, int shade) {
    final baseColor = getStatusColor(status);
    switch (shade) {
      case 50:
        return Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.1);
      case 100:
        return Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.2);
      case 200:
        return Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.3);
      case 300:
        return Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.4);
      case 400:
        return Color.fromRGBO(baseColor.red, baseColor.green, baseColor.blue, 0.5);
      case 500:
        return baseColor;
      case 600:
        return Color.fromRGBO(
          (baseColor.red * 0.8).round(),
          (baseColor.green * 0.8).round(),
          (baseColor.blue * 0.8).round(),
          1.0,
        );
      case 700:
        return Color.fromRGBO(
          (baseColor.red * 0.6).round(),
          (baseColor.green * 0.6).round(),
          (baseColor.blue * 0.6).round(),
          1.0,
        );
      case 800:
        return Color.fromRGBO(
          (baseColor.red * 0.4).round(),
          (baseColor.green * 0.4).round(),
          (baseColor.blue * 0.4).round(),
          1.0,
        );
      case 900:
        return Color.fromRGBO(
          (baseColor.red * 0.2).round(),
          (baseColor.green * 0.2).round(),
          (baseColor.blue * 0.2).round(),
          1.0,
        );
      default:
        return baseColor;
    }
  }

  static Color getContrastTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? noir : blanc;
  }

  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // ===============================================
  // ✅ MÉTHODE kipikCard
  // ===============================================
  
  static Widget kipikCard({
    String? title,
    Widget? child,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color? backgroundColor,
    VoidCallback? onTap,
    Widget? trailing,
    bool showArrow = false,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor ?? noir.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: blanc.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null || trailing != null || showArrow)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (title != null)
                        Expanded(
                          child: Text(
                            title,
                            style: cardTitleStyle,
                          ),
                        ),
                      if (trailing != null) trailing,
                      if (showArrow)
                        Icon(
                          Icons.arrow_forward_ios,
                          color: blanc.withOpacity(0.5),
                          size: 16,
                        ),
                    ],
                  ),
                if ((title != null || trailing != null || showArrow) && child != null)
                  const SizedBox(height: 12),
                if (child != null) child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===============================================
  // ✅ MÉTHODE statusBadge
  // ===============================================
  
  static Widget statusBadge({
    String? status,
    String? text,
    double? fontSize,
    EdgeInsets? padding,
    bool compact = false,
    Color? color,
    IconData? icon,
  }) {
    final displayStatus = status ?? text ?? 'unknown';
    final displayColor = color ?? getStatusColor(displayStatus);
    final bgColor = getStatusColorShade(displayStatus, 100);
    
    return Container(
      padding: padding ?? (compact 
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
        border: Border.all(
          color: displayColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: displayColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text ?? _getStatusText(displayStatus),
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize ?? (compact ? 11 : 12),
              color: displayColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Actif';
      case 'published':
        return 'Publié';
      case 'confirmed':
        return 'Confirmé';
      case 'pending':
        return 'En attente';
      case 'draft':
        return 'Brouillon';
      case 'cancelled':
        return 'Annulé';
      case 'rejected':
        return 'Rejeté';
      case 'finished':
        return 'Terminé';
      default:
        return status;
    }
  }

  // ===============================================
  // ✅ MÉTHODE sectionDivider - NOUVELLE
  // ===============================================
  
  static Widget sectionDivider({
    double? height,
    double? thickness,
    Color? color,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      height: height ?? 1,
      color: color ?? Colors.grey.withOpacity(0.2),
    );
  }

  // ===============================================
  // ✅ MÉTHODE sectionTitle - NOUVELLE
  // ===============================================
  
  static Widget sectionTitle({
    required String title,
    String? subtitle,
    Widget? trailing,
    EdgeInsets? padding,
    Color? color,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: fontTitle,
                    fontSize: 20,
                    color: color ?? blanc,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: (color ?? blanc).withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ===============================================
  // ✅ MÉTHODE shimmer - NOUVELLE
  // ===============================================
  
  static Widget shimmer({
    double? width,
    double? height,
    BorderRadius? borderRadius,
    EdgeInsets? margin,
  }) {
    return Container(
      width: width,
      height: height ?? 20,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        child: LinearProgressIndicator(
          backgroundColor: Colors.grey.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.grey.withOpacity(0.1),
          ),
        ),
      ),
    );
  }

  // ===============================================
  // ✅ MÉTHODE progressIndicator - NOUVELLE
  // ===============================================
  
  static Widget progressIndicator({
    required double value,
    Color? backgroundColor,
    Color? valueColor,
    double? height,
    BorderRadius? borderRadius,
  }) {
    return Container(
      height: height ?? 8,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.withOpacity(0.2),
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value.clamp(0.0, 1.0),
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(valueColor ?? rouge),
          minHeight: height ?? 8,
        ),
      ),
    );
  }

  // ===============================================
  // ✅ MÉTHODE avatar - NOUVELLE
  // ===============================================
  
  static Widget avatar({
    String? imageUrl,
    String? initials,
    double? size,
    Color? backgroundColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    final effectiveSize = size ?? 40;
    
    Widget avatarWidget = CircleAvatar(
      radius: effectiveSize / 2,
      backgroundColor: backgroundColor ?? rouge,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              initials ?? '?',
              style: TextStyle(
                fontFamily: fontTitle,
                fontSize: effectiveSize / 2.5,
                color: textColor ?? blanc,
              ),
            )
          : null,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }
}