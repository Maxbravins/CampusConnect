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

/// Generic yes/no confirmation dialog for destructive actions.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = "Confirm",
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text("No"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
