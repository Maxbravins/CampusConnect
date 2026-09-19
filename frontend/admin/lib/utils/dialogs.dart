import 'package:flutter/material.dart';

/// Shows a confirmation dialog before logging out.
/// Returns true if the user confirmed, false (or null treated as false)
/// if they cancelled.
Future<bool> confirmLogout(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text("Log Out"),
      content: const Text("Are you sure you want to log out?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text("Log Out"),
        ),
      ],
    ),
  );
  return result ?? false;
}
