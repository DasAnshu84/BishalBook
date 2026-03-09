import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'web_download.dart';
import 'date_picker_field.dart';
import 'confirm_delete_dialog.dart';

/// Calculates the sum of a breakdown expression like "100 + 200 + 50".
double calcBreakdownTotal(String breakdown) {
  if (breakdown.trim().isEmpty) return 0;
  try {
    return breakdown
        .split('+')
        .map((s) => double.tryParse(s.trim()) ?? 0)
        .fold(0.0, (a, b) => a + b);
  } catch (_) {
    return 0;
  }
}

/// Parses the JSON list from the API into a normalized list of maps.
List<Map<String, dynamic>> parseScanResponse(List<dynamic> data) {
  return data.map((item) {
    final breakdown = (item['combined_breakdown'] ?? '').toString();
    return {
      'unique_id': (item['unique_id'] ?? '').toString(),
      'combined_breakdown': breakdown,
      'total_amount': calcBreakdownTotal(breakdown),
    };
  }).toList();
}

/// Exports scan results as a CSV string via the share sheet / browser download.
Future<void> downloadScanResults(
  List<Map<String, dynamic>> results,
  void Function(String) onError,
) async {
  if (results.isEmpty) return;
  try {
    final buf = StringBuffer('unique_id,combined_breakdown,total_amount\n');
    for (final item in results) {
      final id = item['unique_id'].toString();
      final bd = item['combined_breakdown'].toString();
      final total = (item['total_amount'] as num).toStringAsFixed(0);
      buf.writeln('"$id","$bd",$total');
    }
    await downloadFileWeb(
        buf.toString(),
        'extracted_ledger_${DateTime.now().millisecondsSinceEpoch}.csv');
  } catch (e) {
    onError('Error downloading file: $e');
  }
}

/// Shows a draggable bottom sheet with editable scan results.
///
/// Returns the edited list if user tapped "Save Changes", or null if dismissed.
Future<List<Map<String, dynamic>>?> showEditableScanResults(
  BuildContext context,
  List<Map<String, dynamic>> scanResults,
) {
  // Create mutable copies for editing
  final editableData = scanResults.map((item) {
    return {
      'unique_id': item['unique_id'].toString(),
      'combined_breakdown': item['combined_breakdown'].toString(),
      'total_amount': (item['total_amount'] as num).toDouble(),
    };
  }).toList();

  DateTime selectedDate = DateTime.now();

  return showModalBottomSheet<List<Map<String, dynamic>>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          double grandTotal = editableData.fold(
              0.0, (sum, item) => sum + (item['total_amount'] as double));

          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFCFAF2),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFDECE2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_note,
                                color: Color(0xFFE86B24), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Extracted Data',
                              style: GoogleFonts.merriweather(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Color(0xFF333333)),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: Colors.grey.shade300),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: DatePickerField(
                        selectedDate: selectedDate,
                        enabled: true,
                        dialogContext: ctx,
                        onDateSelected: (date) {
                          setSheetState(() {
                            selectedDate = date;
                          });
                        },
                      ),
                    ),
                    // ── Column headers ──
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 64,
                            child: Text('ID',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.0)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('BREAKDOWN',
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.0)),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: Text('TOTAL',
                                textAlign: TextAlign.end,
                                style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 1.0)),
                          ),
                        ],
                      ),
                    ),

                    // ── Editable list ──
                    Expanded(
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        controller: controller,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: editableData.length,
                        itemBuilder: (_, i) {
                          final item = editableData[i];
                          return Container(
                            key: ValueKey('${item['unique_id']}_$i'),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                // unique_id
                                SizedBox(
                                  width: 56,
                                  child: TextFormField(
                                    initialValue:
                                        item['unique_id'] as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFE86B24)),
                                    decoration: _fieldDecoration(),
                                    onChanged: (val) {
                                      editableData[i]['unique_id'] = val;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // breakdown
                                Expanded(
                                  child: TextFormField(
                                    initialValue:
                                        item['combined_breakdown']
                                            as String,
                                    style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFF333333)),
                                    decoration: _fieldDecoration(),
                                    onChanged: (val) {
                                      setSheetState(() {
                                        editableData[i]
                                                ['combined_breakdown'] =
                                            val;
                                        editableData[i]['total_amount'] =
                                            calcBreakdownTotal(val);
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // total
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    '₹${(item['total_amount'] as double).toStringAsFixed(0)}',
                                    textAlign: TextAlign.end,
                                    style: GoogleFonts.merriweather(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD35D16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFE86B24)),
                                  onPressed: () async {
                                    final confirm = await showDeleteConfirmDialog(
                                      ctx,
                                      title: "Delete Row",
                                      message: "Are you sure you want to delete this row?",
                                    );

                                    if (confirm == true && i < editableData.length) {
                                      setSheetState(() {
                                        editableData.removeAt(i);
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() {
                              editableData.add({
                                'unique_id': '',
                                'combined_breakdown': '',
                                'total_amount': 0.0,
                              });
                            });
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(
                            "ADD ROW",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE86B24),
                            side: const BorderSide(color: Color(0xFFE86B24)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Grand total + Save ──
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 12, 20,
                          MediaQuery.of(ctx).padding.bottom + 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EFE0),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'GRAND TOTAL',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              Text(
                                '₹${grandTotal.toStringAsFixed(0)}',
                                style: GoogleFonts.merriweather(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFD35D16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final formattedDate =
                                  "${selectedDate.year}-${selectedDate.month.toString().padLeft(2,'0')}-${selectedDate.day.toString().padLeft(2,'0')}";

                                for (final item in editableData) {
                                  item['date'] = formattedDate;
                                }

                                Navigator.pop(ctx, editableData);
                              },
                              icon: const Icon(Icons.save_alt, size: 20),
                              label: Text(
                                'SAVE CHANGES',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                  fontSize: 13,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE86B24),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

InputDecoration _fieldDecoration() {
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE86B24)),
    ),
  );
}
