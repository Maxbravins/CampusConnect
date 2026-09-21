import 'package:flutter/material.dart';

/// Central place for CampusConnect Student App's visual style with Electric Indigo & Soft Lilac.
class AppTheme {
  // Brand Palette Constants
  static const Color electricIndigo = Color(0xFF3F51B5); // Primary Electric Indigo
  static const Color electricIndigoLight = Color(0xFF5C6BC0); // Accent Electric Indigo
  static const Color electricIndigoDark = Color(0xFF303F9F); // Dark Electric Indigo
  static const Color softLilacBg = Color(0xFFF8F7FF); // Soft Lilac Scaffold background
  static const Color softLilacContainer = Color(0xFFF3E8FF); // Soft Lilac card fill
  static const Color softLilacBorder = Color(0xFFE9D5FF); // Soft Lilac border accent
  static const Color softLilacBadge = Color(0xFFDDD6FE); // Soft Lilac badge fill
  static const Color softLilacText = Color(0xFF7E22CE); // Deep Purple text on soft lilac

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3F51B5),
      primary: const Color(0xFF3F51B5),
      secondary: const Color(0xFF3F51B5),
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
        backgroundColor: Color(0xFF3F51B5),
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
          backgroundColor: const Color(0xFF3F51B5),
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
          foregroundColor: const Color(0xFF3F51B5),
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

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: softLilacContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Color(0xFF3F51B5));
          }
          return IconThemeData(color: Colors.grey.shade600);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 12);
          }
          return TextStyle(color: Colors.grey.shade700, fontSize: 12);
        }),
      ),

      chipTheme: ChipThemeData(
        labelStyle: const TextStyle(color: Color(0xFF3F51B5), fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: softLilacBadge,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
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
        return const Color(0xFF3F51B5); // Electric Indigo
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

