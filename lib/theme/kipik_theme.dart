import 'package:flutter/material.dart';

class KipikTheme {
  static const Color noir = Colors.black;
  static const Color blanc = Colors.white;
  static const Color rouge = Color.fromARGB(255, 134, 7, 7);
  static const String fontTitle = 'PermanentMarker';

  static ThemeData themeData = ThemeData(
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
  );
}
