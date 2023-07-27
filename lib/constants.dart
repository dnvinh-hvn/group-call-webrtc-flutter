import 'package:flutter/material.dart';

class Constants {
  static final theme = ThemeData(
    primaryColor: Color(0xfffcfcff),
    hintColor: Colors.orange,
    scaffoldBackgroundColor: Color(0xfffcfcff),
    appBarTheme: AppBarTheme(
      elevation: 0,
      titleTextStyle: TextStyle(
          color: Colors.black,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: Colors.orangeAccent,
    ),
  );
}
