import 'package:flutter/material.dart';

class AppTheme {
  // REDCap Conference colors
  static const Color burgundy = Color(0xFF780000);      // Deep burgundy
  static const Color red = Color(0xFFC1121F);           // Bright red
  static const Color cream = Color(0xFFFDF0D5);         // Cream/beige background
  static const Color darkBlue = Color(0xFF003049);      // Dark blue
  static const Color lightBlue = Color(0xFF669BBC);     // Light blue

  // Alternative theme colors
  static const Color slate = Color(0xFF495867);        // Dark slate
  static const Color slateBlue = Color(0xFF577399);    // Medium blue
  static const Color skyBlue = Color(0xFFBDD5EA);      // Light sky blue
  static const Color offWhite = Color(0xFFF7F7FF);     // Off-white
  static const Color coral = Color(0xFFFE5F55);        // Coral/salmon

  // Warm Earth theme colors
  static const Color terracotta = Color(0xFFD23D2D);   // Terracotta red
  static const Color beige = Color(0xFFF8EECB);        // Warm beige
  static const Color gold = Color(0xFFF5C065);         // Golden yellow
  static const Color forestGreen = Color(0xFF31603D);  // Forest green
  static const Color brown = Color(0xFF6E433D);        // Earth brown

  // Dark Professional theme colors
  static const Color darkRed = Color(0xFF820D0D);      // Dark red
  static const Color brightRed = Color(0xFFD40000);    // Bright red
  static const Color darkGray = Color(0xFF656565);     // Dark gray
  static const Color mediumGray = Color(0xFF898580);   // Medium gray
  static const Color lightGray = Color(0xFFFCFCFC);    // Light gray

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: burgundy,
        onPrimary: cream,
        secondary: red,
        onSecondary: cream,
        tertiary: darkBlue,
        onTertiary: cream,
        surface: cream,
        onSurface: darkBlue,
        surfaceContainerHighest: Color(0xFFEFE6C7), // Slightly darker cream
        primaryContainer: lightBlue,
        onPrimaryContainer: darkBlue,
        secondaryContainer: Color(0xFFE8F4F8), // Very light blue
        onSecondaryContainer: darkBlue,
        outline: darkBlue.withValues(alpha: 0.3),
        error: red,
        onError: cream,
      ),
      scaffoldBackgroundColor: cream,
      appBarTheme: AppBarTheme(
        backgroundColor: burgundy,
        foregroundColor: cream,
        elevation: 0,
        iconTheme: IconThemeData(color: cream),
        titleTextStyle: TextStyle(
          color: cream,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightBlue.withValues(alpha: 0.3),
        selectedColor: lightBlue,
        labelStyle: TextStyle(color: darkBlue),
        secondaryLabelStyle: TextStyle(color: cream),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: burgundy,
          foregroundColor: cream,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: red,
          foregroundColor: cream,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: burgundy,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: lightBlue.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: burgundy, width: 2),
        ),
        prefixIconColor: darkBlue,
        suffixIconColor: darkBlue,
      ),
      iconTheme: IconThemeData(color: darkBlue),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: red,
        foregroundColor: cream,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cream,
        indicatorColor: lightBlue,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: darkBlue, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: darkBlue);
          }
          return IconThemeData(color: darkBlue.withValues(alpha: 0.6));
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cream,
        selectedItemColor: burgundy,
        unselectedItemColor: darkBlue.withValues(alpha: 0.6),
        selectedIconTheme: IconThemeData(color: burgundy),
        unselectedIconTheme: IconThemeData(color: darkBlue.withValues(alpha: 0.6)),
      ),
      dividerColor: lightBlue.withValues(alpha: 0.3),
      badgeTheme: BadgeThemeData(
        backgroundColor: red,
        textColor: cream,
      ),
    );
  
  }
  static ThemeData get blueTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: slate,
        onPrimary: offWhite,
        secondary: coral,
        onSecondary: offWhite,
        tertiary: slateBlue,
        onTertiary: offWhite,
        surface: offWhite,
        onSurface: slate,
        surfaceContainerHighest: Color(0xFFE8E8F5), // Slightly darker off-white
        primaryContainer: slateBlue, // Darker blue for better contrast
        onPrimaryContainer: offWhite,
        secondaryContainer: Color(0xFFFFE8E6), // Very light coral
        onSecondaryContainer: slate,
        outline: slate.withValues(alpha: 0.3),
        error: coral,
        onError: offWhite,
      ),
      scaffoldBackgroundColor: offWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: slate,
        foregroundColor: offWhite,
        elevation: 0,
        iconTheme: IconThemeData(color: offWhite),
        titleTextStyle: TextStyle(
          color: offWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slateBlue.withValues(alpha: 0.3),
        selectedColor: slateBlue,
        labelStyle: TextStyle(color: slate),
        secondaryLabelStyle: TextStyle(color: offWhite),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: slate,
          foregroundColor: offWhite,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: offWhite,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: slate,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: skyBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: skyBlue.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: slate, width: 2),
        ),
        prefixIconColor: slate,
        suffixIconColor: slate,
      ),
      iconTheme: IconThemeData(color: slate),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: coral,
        foregroundColor: offWhite,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: offWhite,
        indicatorColor: skyBlue,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: slate, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: slate);
          }
          return IconThemeData(color: slate.withValues(alpha: 0.6));
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: offWhite,
        selectedItemColor: slate,
        unselectedItemColor: slate.withValues(alpha: 0.6),
        selectedIconTheme: IconThemeData(color: slate),
        unselectedIconTheme: IconThemeData(color: slate.withValues(alpha: 0.6)),
      ),
      dividerColor: skyBlue.withValues(alpha: 0.3),
      badgeTheme: BadgeThemeData(
        backgroundColor: coral,
        textColor: offWhite,
      ),
    );
  }


  static ThemeData get earthTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: forestGreen,
        onPrimary: beige,
        secondary: terracotta,
        onSecondary: beige,
        tertiary: gold,
        onTertiary: brown,
        surface: beige,
        onSurface: brown,
        surfaceContainerHighest: Color(0xFFEFE6BA), // Slightly darker beige
        primaryContainer: Color(0xFF4A7C59), // Medium green
        onPrimaryContainer: beige,
        secondaryContainer: Color(0xFFFFF8E7), // Very light beige
        onSecondaryContainer: brown,
        outline: forestGreen.withValues(alpha: 0.3),
        error: terracotta,
        onError: beige,
      ),
      scaffoldBackgroundColor: beige,
      appBarTheme: AppBarTheme(
        backgroundColor: forestGreen,
        foregroundColor: beige,
        elevation: 0,
        iconTheme: IconThemeData(color: beige),
        titleTextStyle: TextStyle(
          color: beige,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Color(0xFF4A7C59).withValues(alpha: 0.3),
        selectedColor: Color(0xFF4A7C59),
        labelStyle: TextStyle(color: brown),
        secondaryLabelStyle: TextStyle(color: beige),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: forestGreen,
          foregroundColor: beige,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: beige,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: terracotta,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A7C59)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFF4A7C59).withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: forestGreen, width: 2),
        ),
        prefixIconColor: brown,
        suffixIconColor: brown,
      ),
      iconTheme: IconThemeData(color: brown),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: forestGreen,
        foregroundColor: beige,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: beige,
        indicatorColor: gold,
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: brown, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: brown);
          }
          return IconThemeData(color: brown.withValues(alpha: 0.6));
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: beige,
        selectedItemColor: terracotta,
        unselectedItemColor: brown.withValues(alpha: 0.6),
        selectedIconTheme: IconThemeData(color: terracotta),
        unselectedIconTheme: IconThemeData(color: brown.withValues(alpha: 0.6)),
      ),
      dividerColor: gold.withValues(alpha: 0.3),
      badgeTheme: BadgeThemeData(
        backgroundColor: terracotta,
        textColor: beige,
      ),
    );
  }

  static ThemeData get professionalTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: darkRed,
        onPrimary: lightGray,
        secondary: brightRed,
        onSecondary: lightGray,
        tertiary: mediumGray,
        onTertiary: lightGray,
        surface: lightGray,
        onSurface: darkGray,
        surfaceContainerHighest: Color(0xFFEEEEEE), // Slightly darker light gray
        primaryContainer: mediumGray, // Medium gray instead of light gray
        onPrimaryContainer: lightGray,
        secondaryContainer: Color(0xFFFFE5E5), // Very light red
        onSecondaryContainer: darkGray,
        outline: mediumGray.withValues(alpha: 0.3),
        error: brightRed,
        onError: lightGray,
      ),
      scaffoldBackgroundColor: lightGray,
      appBarTheme: AppBarTheme(
        backgroundColor: darkRed,
        foregroundColor: lightGray,
        elevation: 0,
        iconTheme: IconThemeData(color: lightGray),
        titleTextStyle: TextStyle(
          color: lightGray,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: mediumGray.withValues(alpha: 0.3),
        selectedColor: brightRed.withValues(alpha: 0.2),
        labelStyle: TextStyle(color: darkGray),
        secondaryLabelStyle: TextStyle(color: darkGray),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkRed,
          foregroundColor: lightGray,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brightRed,
          foregroundColor: lightGray,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkRed,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mediumGray.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkRed, width: 2),
        ),
        prefixIconColor: darkGray,
        suffixIconColor: darkGray,
      ),
      iconTheme: IconThemeData(color: darkGray),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brightRed,
        foregroundColor: lightGray,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightGray,
        indicatorColor: brightRed.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(color: darkGray, fontSize: 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: darkGray);
          }
          return IconThemeData(color: darkGray.withValues(alpha: 0.6));
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightGray,
        selectedItemColor: darkRed,
        unselectedItemColor: darkGray.withValues(alpha: 0.6),
        selectedIconTheme: IconThemeData(color: darkRed),
        unselectedIconTheme: IconThemeData(color: darkGray.withValues(alpha: 0.6)),
      ),
      dividerColor: mediumGray.withValues(alpha: 0.3),
      badgeTheme: BadgeThemeData(
        backgroundColor: brightRed,
        textColor: lightGray,
      ),
    );
  }
}
