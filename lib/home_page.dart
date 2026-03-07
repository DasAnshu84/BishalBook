import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'clients_page.dart';
import 'transactions_page.dart';
import 'scan_results_sheet.dart';
import 'web_download.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  bool _isTransactionInProgress = false;
  List<Map<String, dynamic>> _scanResults = [];

  void _scanDocument() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFCFAF2),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Image Source',
                  style: GoogleFonts.merriweather(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECE2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Color(0xFFE86B24), size: 22),
                  ),
                  title: Text('Camera',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Take a photo of the ledger',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndProcess(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECE2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library,
                        color: Color(0xFFE86B24), size: 22),
                  ),
                  title: Text('Gallery',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Choose an existing image',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndProcess(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndProcess(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _isLoading = true;
        _scanResults = [];
      });

      final bytes = await pickedFile.readAsBytes();
      await _uploadAndProcessDocument(bytes, pickedFile.name);
    }
  }

  Future<void> _uploadAndProcessDocument(Uint8List imageBytes, String fileName) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstants.fullExtractionUrl),
      );

      request.headers.addAll({
        'Idempotency-Key': 'request-${DateTime.now().millisecondsSinceEpoch}',
      });

      request.files.add(
        http.MultipartFile.fromBytes('file', imageBytes, filename: fileName),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final List<dynamic> data = json.decode(respStr);
        if (mounted) {
          setState(() {
            _scanResults = parseScanResponse(data);
          });
        }
      } else {
        _showError('Failed to process document. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error processing document: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openEditableResults() async {
    if (_scanResults.isEmpty) return;
    final edited = await showEditableScanResults(context, _scanResults);
    if (edited != null && mounted) {
      setState(() => _scanResults = edited);
      _showError('Changes saved locally');
    }
  }

  Future<void> _downloadResults() async {
    await downloadScanResults(_scanResults, _showError);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // ─── Transaction creation ─────────────────────────────────────

  Future<void> _showNewTransactionDialog() async {
    // Fetch clients first for the dropdown
    List<Map<String, dynamic>> clients = [];
    try {
      final resp = await http.get(
        Uri.parse(AppConstants.fullClientsUrl),
        headers: {'accept': 'application/json'},
      );
      if (resp.statusCode == 200) {
        clients = (json.decode(resp.body) as List).cast<Map<String, dynamic>>();
      }
    } catch (_) {}

    if (!mounted) return;

    if (clients.isEmpty) {
      _showError('No clients found. Please create a client first.');
      return;
    }

    String? selectedClientId = clients.first['id'];
    final amountCtrl = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFCFAF2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECE2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.post_add,
                        color: Color(0xFFE86B24), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'New Transaction',
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Client',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedClientId,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFFE86B24)),
                        items: clients.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(
                              '${c['client_name']} (${c['client_code']})',
                              style: GoogleFonts.inter(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: submitting
                            ? null
                            : (val) {
                                setDialogState(
                                    () => selectedClientId = val);
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Amount',
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    enabled: !submitting,
                    decoration: InputDecoration(
                      hintText: 'e.g. 1500.50',
                      prefixIcon: const Icon(Icons.currency_rupee,
                          color: Color(0xFFE86B24), size: 20),
                      filled: true,
                      fillColor: submitting
                          ? Colors.grey.shade200
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE86B24), width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      submitting ? null : () => Navigator.pop(ctx),
                  child: Text('Cancel',
                      style:
                          GoogleFonts.inter(color: Colors.grey.shade600)),
                ),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final amount =
                              double.tryParse(amountCtrl.text.trim());
                          if (amount == null || amount <= 0) {
                            _showError('Enter a valid amount');
                            return;
                          }
                          setDialogState(() => submitting = true);
                          setState(
                              () => _isTransactionInProgress = true);
                          try {
                            final resp = await http.post(
                              Uri.parse(
                                  AppConstants.fullTransactionsUrl),
                              headers: {
                                'Content-Type': 'application/json'
                              },
                              body: json.encode({
                                'client_id': selectedClientId,
                                'transaction_amount': amount,
                              }),
                            );
                            if (resp.statusCode == 200 ||
                                resp.statusCode == 201) {
                              if (mounted) Navigator.pop(ctx);
                              _showError(
                                  'Transaction created successfully');
                            } else {
                              _showError(
                                  'Failed (${resp.statusCode})');
                            }
                          } catch (e) {
                            _showError('Error: $e');
                          } finally {
                            if (mounted) {
                              setState(() =>
                                  _isTransactionInProgress = false);
                            }
                            setDialogState(() => submitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE86B24),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Submit',
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final buttonAreaHeight = 55 + 20 + bottomPadding; // button + top margin + safe area

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, buttonAreaHeight + 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('CLIENTS RECORD'),
                  const SizedBox(height: 15),
                  _buildAccountBalancesCard(),
                  const SizedBox(height: 30),
                  _buildSectionTitle('TRANSACTION LOG'),
                  const SizedBox(height: 15),
                  _buildTransactionLogCard(),
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE86B24),
                ),
              ),
            ),

          if (_scanResults.isNotEmpty && !_isLoading)
            Positioned(
              bottom: buttonAreaHeight + 12,
              left: 20,
              right: 20,
              child: _buildResultCard(),
            ),

          _buildBottomActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE86B24), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 10),
              Text(
                'Scan Complete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_red_eye, color: Color(0xFFE86B24)),
                tooltip: 'View & Edit Data',
                onPressed: _openEditableResults,
              ),
              IconButton(
                icon: const Icon(Icons.download, color: Color(0xFFE86B24)),
                tooltip: 'Download CSV',
                onPressed: _downloadResults,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF4A4A4A),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_book, color: Colors.white),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bishal Book',
                style: GoogleFonts.merriweather(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF333333),
                ),
              ),
              Text(
                'REGISTRY VOLUME I',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Icon(Icons.send_time_extension, color: Color(0xFF333333)),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildAccountBalancesCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ClientsPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clients Enrolled',
                      style: GoogleFonts.merriweather(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Manage your registered clients',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECE2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.people_alt,
                    color: Color(0xFFE86B24),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  height: 35,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFF4A4A4A),
                          child: const Text('JD', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                      Positioned(
                        left: 25,
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFFE86B24),
                          child: const Text('SM', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                      Positioned(
                        left: 50,
                        child: CircleAvatar(
                          radius: 17,
                          backgroundColor: const Color(0xFFD6CDB8),
                          child: const Text('RK', style: TextStyle(color: Colors.black, fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '8 active records',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'VIEW CLIENTS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.open_in_new, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionLogCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TransactionsPage()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildTransactionItem(
              icon: Icons.account_balance_wallet,
              title: 'Sarah Miller',
              subtitle: 'Repayment • 2 hours past',
              amount: '+\$250.00',
              isPositive: true,
            ),
            const SizedBox(height: 20),
            _buildTransactionItem(
              icon: Icons.edit,
              title: 'Office Supplies',
              subtitle: 'Expense • Today, 10:15 AM',
              amount: '-\$42.30',
              isPositive: false,
            ),
            const SizedBox(height: 20),
            _buildTransactionItem(
              icon: Icons.local_cafe,
              title: 'Market Coffee',
              subtitle: 'Petty Cash • Yesterday',
              amount: '-\$5.50',
              isPositive: false,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 15),
            Text(
              'VIEW FULL CHRONOLOGY',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: const Color(0xFFE86B24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required bool isPositive,
  }) {
    return Row(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: const Color(0xFFF3EFE0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Icon(icon, color: const Color(0xFFE86B24), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.merriweather(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: GoogleFonts.merriweather(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isPositive ? const Color(0xFFD35D16) : const Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFE0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFFE86B24),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE86B24).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isTransactionInProgress
                        ? null
                        : _showNewTransactionDialog,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.post_add, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'NEW ENTRY',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFAF2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _scanDocument,
                    borderRadius: BorderRadius.circular(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.document_scanner, color: Color(0xFFE86B24)),
                        const SizedBox(width: 10),
                        Text(
                          'SCAN',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF333333),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
