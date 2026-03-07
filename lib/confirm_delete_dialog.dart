import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shows a themed confirmation dialog for delete actions.
///
/// Returns `true` if user confirmed, `false` or `null` otherwise.
///
/// [title] — Dialog title, e.g. "Delete Client"
/// [message] — Body text, e.g. "Are you sure you want to delete this client?"
Future<bool?> showDeleteConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFFFCFAF2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade400, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade700),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('CANCEL',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 12,
                  color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text('DELETE',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  fontSize: 12)),
        ),
      ],
    ),
  );
}
