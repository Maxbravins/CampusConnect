import 'package:flutter/material.dart';

/// Central place for CampusConnect Admin's visual style with Electric Indigo & Soft Lilac.
class AppTheme {
  // Brand Palette Constants
  static const Color electricIndigo = Color(0xFF4F46E5); // Primary Electric Indigo
  static const Color electricIndigoLight = Color(0xFF6366F1); // Accent Electric Indigo
  static const Color electricIndigoDark = Color(0xFF3730A3); // Dark Electric Indigo
  static const Color softLilacBg = Color(0xFFF8F7FF); // Soft Lilac Scaffold background
  static const Color softLilacContainer = Color(0xFFF3E8FF); // Soft Lilac card fill
  static const Color softLilacBorder = Color(0xFFE9D5FF); // Soft Lilac border accent
  static const Color softLilacBadge = Color(0xFFDDD6FE); // Soft Lilac badge fill
  static const Color softLilacText = Color(0xFF7E22CE); // Deep Purple text on soft lilac

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: electricIndigo,
      primary: electricIndigo,
      secondary: electricIndigoLight,
      surface: softLilacBg,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFAFAFE),
      surfaceContainer: softLilacContainer,
      surfaceContainerHigh: softLilacBadge,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: softLilacBg,

      appBarTheme: const AppBarTheme(
        backgroundColor: electricIndigo,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: softLilacBorder, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: electricIndigo,
          side: const BorderSide(color: softLilacBorder, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softLilacBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: softLilacBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: electricIndigo, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(color: electricIndigo, fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: softLilacBadge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: electricIndigo),
        unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
        selectedLabelTextStyle: const TextStyle(
          color: electricIndigo,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 13,
        ),
        indicatorColor: softLilacContainer,
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
      ),
    );
  }
    /// Dark theme variant for CampusConnect Admin, maintaining Electric Indigo & Soft Lilac aesthetics.
  static ThemeData get dark {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: electricIndigo,
    brightness: Brightness.dark,
    primary: electricIndigoLight,
    secondary: electricIndigoLight,
    surface: const Color(0xFF11121F),
    surfaceContainerLowest: const Color(0xFF0B0C14),
    surfaceContainerLow: const Color(0xFF151625),
    surfaceContainer: const Color(0xFF1B1C2C),
    surfaceContainerHigh: const Color(0xFF24263A),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF11121F),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF252657),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFF1B1C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.deepPurple.shade700,
          width: 1,
        ),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: electricIndigoLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: electricIndigoLight,
        side: BorderSide(
          color: Colors.deepPurple.shade400,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.deepPurple.shade700,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.deepPurple.shade700,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: electricIndigoLight,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: const Color(0xFF1B1C2C),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    chipTheme: ChipThemeData(
      labelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: const Color(0xFF30315A),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
    ),

    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: const Color(0xFF151625),
      selectedIconTheme: const IconThemeData(
        color: electricIndigoLight,
      ),
      unselectedIconTheme: IconThemeData(
        color: Colors.grey.shade400,
      ),
      selectedLabelTextStyle: const TextStyle(
        color: electricIndigoLight,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 13,
      ),
      indicatorColor: const Color(0xFF30315A),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      tileColor: Colors.transparent,
      iconColor: electricIndigoLight,
    ),
  );
}

  /// Status badge colors aligned with Electric Indigo & Soft Lilac theme
  static Color getStatusColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFF59E0B); // Amber
      case "Payment Required":
        return const Color(0xFFEA580C); // Warm Orange
      case "Paid":
        return electricIndigo; // Electric Indigo
      case "Processing":
        return const Color(0xFF8B5CF6); // Soft Purple
      case "Completed":
        return const Color(0xFF10B981); // Emerald Green
      default:
        return Colors.grey.shade600;
    }
  }

  static Color getStatusBgColor(String status) {
    switch (status) {
      case "Pending":
        return const Color(0xFFFEF3C7);
      case "Payment Required":
        return const Color(0xFFFFEDD5);
      case "Paid":
        return softLilacContainer;
      case "Processing":
        return const Color(0xFFF3E8FF);
      case "Completed":
        return const Color(0xFFD1FAE5);
      default:
        return Colors.grey.shade200;
    }
  }
}

