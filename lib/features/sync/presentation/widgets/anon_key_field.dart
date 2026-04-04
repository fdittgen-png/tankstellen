import 'package:flutter/material.dart';

/// Text field for entering a Supabase anon key with:
/// - Visibility toggle to verify the full key was pasted
/// - Character count with color (green=correct, orange=truncated)
/// - Helper text explaining expected length
class AnonKeyField extends StatelessWidget {
  final TextEditingController controller;
  final bool showKey;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onChanged;

  /// Minimum expected length of a Supabase anon key (JWT token).
  static const minExpectedKeyLength = 200;
  /// Safe upper bound for key length validation.
  static const maxKeyLength = 512;

  const AnonKeyField({
    super.key,
    required this.controller,
    required this.showKey,
    required this.onToggleVisibility,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final keyLen = controller.text.length;
    final isComplete = keyLen >= minExpectedKeyLength;
    final isTooLong = keyLen > maxKeyLength;
    final isJwtFormat = controller.text.split('.').length == 3;

    String? helperText;
    Color helperColor = Colors.orange;
    if (keyLen > 0) {
      if (isTooLong) {
        helperText = 'Key is too long ($keyLen chars) — check for extra text';
        helperColor = Colors.red;
      } else if (isComplete && isJwtFormat) {
        helperText = 'Key looks correct ($keyLen chars)';
        helperColor = Colors.green;
      } else if (!isJwtFormat && keyLen > 10) {
        helperText = 'Key should be a JWT (header.payload.signature)';
        helperColor = Colors.red;
      } else {
        helperText = 'Key may be truncated ($keyLen of ~208 expected chars)';
      }
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Anon Key',
        hintText: 'eyJhbGciOiJIUzI1NiIs...',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.key),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (keyLen > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$keyLen',
                  style: TextStyle(fontSize: 11, color: isComplete ? Colors.green : Colors.orange),
                ),
              ),
            IconButton(
              icon: Icon(showKey ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: onToggleVisibility,
              tooltip: showKey ? 'Hide key' : 'Show key to verify',
            ),
          ],
        ),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: TextStyle(color: helperColor, fontSize: 11),
        errorText: isTooLong ? 'Key exceeds maximum length' : null,
      ),
      obscureText: !showKey,
      maxLines: showKey ? 3 : 1,
      style: TextStyle(fontSize: showKey ? 11 : 13),
      onChanged: (_) => onChanged?.call(),
    );
  }
}
