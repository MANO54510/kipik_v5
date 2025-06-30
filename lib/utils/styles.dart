// Fichier : lib/utils/styles.dart
// Description : Constantes visuelles et de style pour l'application Kipik

import 'package:flutter/material.dart';

// Couleurs de l'application
const Color kPrimaryColor = Color(0xFF3E7BFA);      // Bleu principal
const Color kPrimaryLightColor = Color(0xFFE8F1FF); // Bleu clair
const Color kAccentColor = Color(0xFFFF9500);       // Orange accent
const Color kBackgroundColor = Color(0xFFF8F9FC);   // Fond d'écran léger
const Color kCardColor = Colors.white;
const Color kErrorColor = Color(0xFFE53935);        // Rouge erreur
const Color kSuccessColor = Color(0xFF4CAF50);      // Vert succès
const Color kWarningColor = Color(0xFFFFC107);      // Jaune avertissement
const Color kInfoColor = Color(0xFF2196F3);         // Bleu info
const Color kTextColor = Color(0xFF2D3142);         // Texte principal
const Color kTextLightColor = Color(0xFF9E9E9E);    // Texte secondaire
const Color kBorderColor = Color(0xFFE0E0E0);       // Bordures
const Color kStarColor = Color(0xFFFFD700);         // Couleur des étoiles (note)
const Color kButtonColor = kPrimaryColor;
const Color kButtonTextColor = Colors.white;

// Durées d'animation
const Duration kAnimationDuration = Duration(milliseconds: 200);
const Duration kSnackBarDuration = Duration(seconds: 3);

// Padding et marges
const double kDefaultPadding = 16.0;
const double kSmallPadding = 8.0;
const double kLargePadding = 24.0;
const double kExtraLargePadding = 32.0;

// Rayons de bordure
const double kDefaultBorderRadius = 12.0;
const double kSmallBorderRadius = 8.0;
const double kLargeBorderRadius = 16.0;
const double kButtonBorderRadius = 30.0;
const double kCardBorderRadius = 12.0;

// Tailles d'élévation
const double kDefaultElevation = 2.0;
const double kCardElevation = 3.0;
const double kButtonElevation = 4.0;

// Tailles de police
const double kHeadlineLargeSize = 28.0;
const double kHeadlineMediumSize = 24.0;
const double kHeadlineSmallSize = 20.0;
const double kTitleLargeSize = 18.0;
const double kTitleMediumSize = 16.0;
const double kTitleSmallSize = 14.0;
const double kBodyLargeSize = 16.0;
const double kBodyMediumSize = 14.0;
const double kBodySmallSize = 12.0;
const double kCaptionSize = 10.0;

// Hauteurs
const double kAppBarHeight = 56.0;
const double kBottomNavBarHeight = 60.0;
const double kButtonHeight = 50.0;
const double kSmallButtonHeight = 40.0;
const double kInputHeight = 56.0;
const double kTabBarHeight = 48.0;

// Largeurs
const double kMaxContentWidth = 600.0;
const double kButtonMinWidth = 120.0;

// Rayons d'image
const double kAvatarRadius = 32.0;
const double kSmallAvatarRadius = 20.0;
const double kLargeAvatarRadius = 48.0;

// Propriétés de texte
const TextStyle kHeadlineLargeStyle = TextStyle(
  fontSize: kHeadlineLargeSize,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kHeadlineMediumStyle = TextStyle(
  fontSize: kHeadlineMediumSize,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kHeadlineSmallStyle = TextStyle(
  fontSize: kHeadlineSmallSize,
  fontWeight: FontWeight.bold,
  color: kTextColor,
);

const TextStyle kTitleLargeStyle = TextStyle(
  fontSize: kTitleLargeSize,
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const TextStyle kTitleMediumStyle = TextStyle(
  fontSize: kTitleMediumSize,
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const TextStyle kTitleSmallStyle = TextStyle(
  fontSize: kTitleSmallSize,
  fontWeight: FontWeight.w600,
  color: kTextColor,
);

const TextStyle kBodyLargeStyle = TextStyle(
  fontSize: kBodyLargeSize,
  color: kTextColor,
);

const TextStyle kBodyMediumStyle = TextStyle(
  fontSize: kBodyMediumSize,
  color: kTextColor,
);

const TextStyle kBodySmallStyle = TextStyle(
  fontSize: kBodySmallSize,
  color: kTextColor,
);

const TextStyle kCaptionStyle = TextStyle(
  fontSize: kCaptionSize,
  color: kTextLightColor,
);

const TextStyle kButtonTextStyle = TextStyle(
  fontSize: kBodyMediumSize,
  fontWeight: FontWeight.w600,
  color: kButtonTextColor,
);

// Ombres
const List<BoxShadow> kDefaultBoxShadow = [
  BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  ),
];

const List<BoxShadow> kCardBoxShadow = [
  BoxShadow(
    color: Color(0x1A000000),
    offset: Offset(0, 2),
    blurRadius: 8,
    spreadRadius: 0,
  ),
];

const List<BoxShadow> kButtonBoxShadow = [
  BoxShadow(
    color: Color(0x29000000),
    offset: Offset(0, 3),
    blurRadius: 6,
    spreadRadius: 0,
  ),
];

// Paramètres graphiques
const double kDefaultLineWidth = 2.0;
const double kDefaultCircleRadius = 4.0;
const Duration kDefaultAnimationDuration = Duration(milliseconds: 500);

// Thème clair
ThemeData getLightTheme() {
  return ThemeData(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: kBackgroundColor,
    colorScheme: ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kAccentColor,
      error: kErrorColor,
      background: kBackgroundColor,
      surface: kCardColor,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      color: kCardColor,
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardBorderRadius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kButtonColor,
        foregroundColor: kButtonTextColor,
        elevation: kButtonElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kButtonBorderRadius),
        ),
        minimumSize: Size(kButtonMinWidth, kButtonHeight),
        textStyle: kButtonTextStyle,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kPrimaryColor,
        textStyle: kButtonTextStyle,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kPrimaryColor,
        side: const BorderSide(color: kPrimaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kButtonBorderRadius),
        ),
        minimumSize: Size(kButtonMinWidth, kButtonHeight),
        textStyle: kButtonTextStyle,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: kDefaultPadding,
        vertical: kDefaultPadding * 0.75,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        borderSide: const BorderSide(color: kBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        borderSide: const BorderSide(color: kPrimaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
        borderSide: const BorderSide(color: kErrorColor),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: kHeadlineLargeStyle,
      headlineMedium: kHeadlineMediumStyle,
      headlineSmall: kHeadlineSmallStyle,
      titleLarge: kTitleLargeStyle,
      titleMedium: kTitleMediumStyle,
      titleSmall: kTitleSmallStyle,
      bodyLarge: kBodyLargeStyle,
      bodyMedium: kBodyMediumStyle,
      bodySmall: kBodySmallStyle,
      labelMedium: kButtonTextStyle,
    ),
    dividerTheme: const DividerThemeData(
      color: kBorderColor,
      thickness: 1,
      space: 1,
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: kPrimaryColor,
      unselectedLabelColor: kTextLightColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
    ),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: kTextLightColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}

// Thème sombre
ThemeData getDarkTheme() {
  return ThemeData.dark().copyWith(
    primaryColor: kPrimaryColor,
    scaffoldBackgroundColor: const Color(0xFF121212),
    colorScheme: const ColorScheme.dark(
      primary: kPrimaryColor,
      secondary: kAccentColor,
      error: kErrorColor,
      surface: Color(0xFF1E1E1E),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF2A2A2A),
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kCardBorderRadius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kButtonColor,
        foregroundColor: kButtonTextColor,
        elevation: kButtonElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kButtonBorderRadius),
        ),
        minimumSize: Size(kButtonMinWidth, kButtonHeight),
        textStyle: kButtonTextStyle,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kDefaultBorderRadius),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: kPrimaryColor,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
  );
}