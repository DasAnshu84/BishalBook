import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'confirm_delete_dialog.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  bool _isActionInProgress = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimController;


  final List<String> _alphabet = List.generate(
    26,
    (i) => String.fromCharCode(65 + i),
  );

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchClients();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  // ─── API helpers ────────────────────────────────────────────────

  Future<void> _fetchClients() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(AppConstants.fullClientsUrl),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _clients = data.cast<Map<String, dynamic>>();
          _clients.sort((a, b) =>
              (a['client_name'] ?? '').compareTo(b['client_name'] ?? ''));
        });
      } else {
        _showSnack('Failed to load clients (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createClient(String name, String code) async {
    setState(() => _isActionInProgress = true);
    try {
      final response = await http.post(
        Uri.parse(AppConstants.fullClientsUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'client_name': name, 'client_code': code}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnack('Client created successfully');
        await _fetchClients();
      } else {
        _showSnack('Failed to create client (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _updateClient(
      String id, String name, String code) async {
    setState(() => _isActionInProgress = true);
    try {
      final body = <String, dynamic>{'client_name': name};
      if (code.isNotEmpty) body['client_code'] = code;

      final response = await http.put(
        Uri.parse('${AppConstants.fullClientsUrl}$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        _showSnack('Client updated successfully');
        await _fetchClients();
      } else {
        _showSnack('Failed to update client (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _deleteClient(String id) async {
    setState(() => _isActionInProgress = true);
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.fullClientsUrl}$id'),
        headers: {'accept': 'application/json'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSnack('Client deleted');
        await _fetchClients();
      } else {
        _showSnack('Failed to delete client (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4A4A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Scroll ─────────────────────────────────────────────────────
  void _scrollToLetter(String letter) {
    final index = _clients.indexWhere((c) =>
        (c['client_name'] ?? '').toUpperCase().startsWith(letter));

    if (index != -1) {
      _scrollController.animateTo(
        index * 92.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // ─── Dialogs ────────────────────────────────────────────────────

  void _showCreateOrEditDialog({Map<String, dynamic>? client}) {
    final isEdit = client != null;
    final nameCtrl =
        TextEditingController(text: isEdit ? client['client_name'] ?? '' : '');
    final codeCtrl =
        TextEditingController(text: isEdit ? client['client_code'] ?? '' : '');

    showDialog(
      context: context,
      barrierDismissible: !_isActionInProgress,
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
                    child: Icon(
                      isEdit ? Icons.edit_note : Icons.person_add,
                      color: const Color(0xFFE86B24),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Edit Client' : 'New Client',
                    style: GoogleFonts.merriweather(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _styledTextField(
                    controller: nameCtrl,
                    label: 'Client Name',
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 14),
                  _styledTextField(
                    controller: codeCtrl,
                    label: 'Client Code',
                    icon: Icons.tag,
                    enabled: !isEdit,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isActionInProgress ? null : () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isActionInProgress
                      ? null
                      : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            _showSnack('Client name is required');
                            return;
                          }
                          if (!isEdit && codeCtrl.text.trim().isEmpty) {
                            _showSnack('Client code is required');
                            return;
                          }
                          Navigator.pop(ctx);
                          if (isEdit) {
                            await _updateClient(
                                client['id'], nameCtrl.text.trim(),
                                codeCtrl.text.trim());
                          } else {
                            await _createClient(
                                nameCtrl.text.trim(), codeCtrl.text.trim());
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE86B24),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isActionInProgress
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'Update' : 'Create',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> client) async {
    final confirm = await showDeleteConfirmDialog(
      context,
      title: 'Delete Client',
      message:
          'Are you sure you want to delete ${client['client_name'] ?? 'this client'}? This action cannot be undone.',
    );

    if (confirm == true) {
      await _deleteClient(client['id']);
    }
  }

  void _showClientDetails(Map<String, dynamic> client) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCFAF2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECE2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials(client['client_name'] ?? ''),
                        style: GoogleFonts.merriweather(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE86B24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['client_name'] ?? '',
                          style: GoogleFonts.merriweather(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE86B24).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            client['client_code'] ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE86B24),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Detail rows
              _detailRow(
                  Icons.fingerprint, 'ID', _shortId(client['id'] ?? '')),
              const SizedBox(height: 12),
              _detailRow(Icons.calendar_today, 'Created',
                  _formatDate(client['created_at'])),
              const SizedBox(height: 12),
              _detailRow(Icons.update, 'Updated',
                  _formatDate(client['updated_at'])),
              const SizedBox(height: 12),
              _detailRow(Icons.person, 'Created By',
                  client['created_by'] ?? 'N/A'),
              const SizedBox(height: 12),
              _detailRow(Icons.person_outline, 'Updated By',
                  client['updated_by'] ?? 'N/A'),

              const SizedBox(height: 28),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.edit_outlined,
                      label: 'EDIT',
                      color: const Color(0xFFE86B24),
                      onPressed: _isActionInProgress
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _showCreateOrEditDialog(client: client);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.delete_outline,
                      label: 'DELETE',
                      color: Colors.red.shade400,
                      onPressed: _isActionInProgress
                          ? null
                          : () {
                              Navigator.pop(ctx);
                              _showDeleteConfirmation(client);
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ─── UI helpers ─────────────────────────────────────────────────

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: const Color(0xFFE86B24), size: 20),
        filled: true,
        fillColor:
            enabled ? Colors.white : Colors.grey.shade200,
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
          borderSide:
              const BorderSide(color: Color(0xFFE86B24), width: 1.5),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: color.withOpacity(0.4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF333333)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _shortId(String id) {
    return id.length > 8 ? '${id.substring(0, 8)}…' : id;
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  // ─── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3EFE0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3EFE0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Color(0xFF333333), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clients Enrolled',
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            Text(
              'CLIENT REGISTRY',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFE86B24)),
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _fetchClients,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            _isActionInProgress ? null : () => _showCreateOrEditDialog(),
        backgroundColor:
            _isActionInProgress ? Colors.grey : const Color(0xFFE86B24),
        icon: _isActionInProgress
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.person_add, color: Colors.white),
        label: Text(
          'NEW CLIENT',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            fontSize: 12,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE86B24)),
            )
          : _clients.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFE86B24),
                  onRefresh: _fetchClients,
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 36, 100),
                        itemCount: _clients.length,
                        itemBuilder: (_, i) => _buildClientCard(_clients[i], i),
                      ),

Positioned(
  right: 4,
  top: 20,
  bottom: 20,
  width: 30, // Explicit width makes the "hit area" easier to grab
  child: GestureDetector(
    behavior: HitTestBehavior.opaque, // Ensures the gaps between letters are clickable
    onVerticalDragUpdate: (details) {
      // Calculate which letter we are over based on the total height
      double scrollPercent = details.localPosition.dy / (MediaQuery.of(context).size.height - 40);
      int index = (scrollPercent * _alphabet.length).floor().clamp(0, _alphabet.length - 1);
      _scrollToLetter(_alphabet[index]);
    },
    onTapDown: (details) {
      double scrollPercent = details.localPosition.dy / (MediaQuery.of(context).size.height - 40);
      int index = (scrollPercent * _alphabet.length).floor().clamp(0, _alphabet.length - 1);
      _scrollToLetter(_alphabet[index]);
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _alphabet.map((letter) {
        return Expanded( // Expanded ensures letters are spaced evenly across the height
          child: Center(
            child: Text(
              letter,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  ),
)                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFDECE2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people_outline,
                color: Color(0xFFE86B24), size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No Clients Yet',
            style: GoogleFonts.merriweather(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to enroll your first client',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(Map<String, dynamic> client, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 80)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showClientDetails(client),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFDECE2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _initials(client['client_name'] ?? ''),
                        style: GoogleFonts.merriweather(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE86B24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client['client_name'] ?? '',
                          style: GoogleFonts.merriweather(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE86B24).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                client['client_code'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE86B24),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (client['created_by'] != null)
                              Text(
                                'by ${client['created_by']}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _iconAction(
                        Icons.edit_outlined,
                        const Color(0xFFE86B24),
                        _isActionInProgress
                            ? null
                            : () =>
                                _showCreateOrEditDialog(client: client),
                      ),
                      const SizedBox(width: 4),
                      _iconAction(
                        Icons.delete_outline,
                        Colors.red.shade400,
                        _isActionInProgress
                            ? null
                            : () => _showDeleteConfirmation(client),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconAction(IconData icon, Color color, VoidCallback? onPressed) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        color: onPressed == null ? Colors.grey.shade400 : color,
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ),
    );
  }
}
