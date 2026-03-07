import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';
import 'confirm_delete_dialog.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // ─── State ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Pagination
  static const int _pageSize = 10;
  int _currentSkip = 0;

  // Filters
  String? _selectedClientId;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _filtersExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
    _fetchTransactions(reset: true);
  }

  // ─── API ────────────────────────────────────────────────────────

  Future<void> _loadClients() async {
    try {
      final resp = await http.get(
        Uri.parse(AppConstants.fullClientsUrl),
        headers: {'accept': 'application/json'},
      );
      if (resp.statusCode == 200) {
        setState(() {
          _clients =
              (json.decode(resp.body) as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchTransactions({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentSkip = 0;
        _transactions = [];
        _hasMore = true;
        _isLoading = true;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final params = <String, String>{
        'skip': _currentSkip.toString(),
        'limit': _pageSize.toString(),
      };

      if (_selectedClientId != null && _selectedClientId!.isNotEmpty) {
        params['client_id'] = _selectedClientId!;
      }
      if (_startDate != null) {
        params['start_date'] = _fmtDate(_startDate!);
      }
      if (_endDate != null) {
        params['end_date'] = _fmtDate(_endDate!);
      }

      final uri = Uri.parse(AppConstants.fullTransactionsUrl)
          .replace(queryParameters: params);

      final resp =
          await http.get(uri, headers: {'accept': 'application/json'});

      if (resp.statusCode == 200) {
        final data =
            (json.decode(resp.body) as List).cast<Map<String, dynamic>>();
        setState(() {
          _transactions.addAll(data);
          _currentSkip += data.length;
          _hasMore = data.length >= _pageSize;
        });
      } else {
        _snack('Failed to load transactions (${resp.statusCode})');
      }
    } catch (e) {
      _snack('Network error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _applyFilters() {
    _fetchTransactions(reset: true);
    setState(() => _filtersExpanded = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedClientId = null;
      _startDate = null;
      _endDate = null;
    });
    _fetchTransactions(reset: true);
  }

  // ─── Helpers ────────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(iso).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _snack(String msg) {
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

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE86B24),
              onPrimary: Colors.white,
              surface: Color(0xFFFCFAF2),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
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
              'Transaction Log',
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            Text(
              'FULL CHRONOLOGY',
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
            icon: Icon(
              _filtersExpanded
                  ? Icons.filter_list_off
                  : Icons.filter_list,
              color: const Color(0xFFE86B24),
            ),
            tooltip: 'Toggle Filters',
            onPressed: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter panel ──
          AnimatedCrossFade(
            firstChild: _buildFilterPanel(),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _filtersExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 250),
          ),

          // ── Transaction list ──
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFE86B24)),
                  )
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        color: const Color(0xFFE86B24),
                        onRefresh: () => _fetchTransactions(reset: true),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount:
                              _transactions.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == _transactions.length) {
                              return _buildLoadMoreButton();
                            }
                            return _buildTransactionCard(
                                _transactions[i], i);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ─── Filter panel ───────────────────────────────────────────────

  Widget _buildFilterPanel() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFAF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range row
          Text('Date Range',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _dateChip('From', _startDate, true)),
              const SizedBox(width: 10),
              Expanded(child: _dateChip('To', _endDate, false)),
            ],
          ),

          const SizedBox(height: 14),

          // Client dropdown
          Text('Client',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClientId,
                isExpanded: true,
                hint: Text('All Clients',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.grey.shade500)),
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFFE86B24)),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('All Clients',
                        style: GoogleFonts.inter(fontSize: 14)),
                  ),
                  ..._clients.map((c) {
                    return DropdownMenuItem<String>(
                      value: c['id'],
                      child: Text(
                        '${c['client_name']} (${c['client_code']})',
                        style: GoogleFonts.inter(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (val) =>
                    setState(() => _selectedClientId = val),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.search, size: 18),
                    label: Text('APPLY',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE86B24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('CLEAR',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, DateTime? date, bool isStart) {
    return GestureDetector(
      onTap: () => _pickDate(isStart: isStart),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null
                ? const Color(0xFFE86B24)
                : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today,
                size: 16,
                color: date != null
                    ? const Color(0xFFE86B24)
                    : Colors.grey.shade500),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? _fmtDate(date) : label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: date != null
                      ? const Color(0xFF333333)
                      : Colors.grey.shade500,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isStart) {
                      _startDate = null;
                    } else {
                      _endDate = null;
                    }
                  });
                },
                child: Icon(Icons.close,
                    size: 16, color: Colors.grey.shade500),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Empty state ────────────────────────────────────────────────

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
            child: const Icon(Icons.receipt_long,
                color: Color(0xFFE86B24), size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'No Transactions Found',
            style: GoogleFonts.merriweather(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or create a transaction',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ─── Load more ──────────────────────────────────────────────────

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator(color: Color(0xFFE86B24))
            : SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _fetchTransactions(),
                  icon: const Icon(Icons.expand_more, size: 18),
                  label: Text('LOAD MORE',
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE86B24),
                    side: const BorderSide(color: Color(0xFFE86B24)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Delete Actions ─────────────────────────────────────────────

  Future<void> _confirmDeleteTransaction(String? id) async {
    if (id == null || id.isEmpty) {
      _snack('Cannot delete: transaction ID not found');
      return;
    }

    final confirm = await showDeleteConfirmDialog(
      context,
      title: 'Delete Transaction',
      message: 'Are you sure you want to delete this transaction?',
    );

    if (confirm == true) {
      _deleteTransaction(id);
    }
  }

  Future<void> _deleteTransaction(String id) async {
    
    try {
      final uri = Uri.parse('${AppConstants.fullTransactionsUrl}$id');
      final resp = await http.delete(uri, headers: {'accept': 'application/json'});
      
      if (resp.statusCode == 200 || resp.statusCode == 204) {
        setState(() {
          _transactions.removeWhere(
              (t) => t['transaction_uuid']?.toString() == id);
        });
        _snack('Transaction deleted successfully');
      } else {
        _snack('Failed to delete transaction: ${resp.statusCode}');
      }
    } catch (e) {
      _snack('Network error: $e');
    }
  }

  // ─── Transaction card ───────────────────────────────────────────

  Widget _buildTransactionCard(Map<String, dynamic> txn, int index) {
    final clientInfo = txn['clients'] as Map<String, dynamic>?;
    final clientName = clientInfo?['client_name'] ?? 'Unknown';
    final clientCode = clientInfo?['client_code'] ?? '';
    final amount = txn['transaction_amount'];
    final dateStr = _displayDate(txn['created_at']);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFAF2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  _initials(clientName),
                  style: GoogleFonts.merriweather(
                    fontSize: 13,
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
                    clientName,
                    style: GoogleFonts.merriweather(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (clientCode.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE86B24).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            clientCode,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE86B24),
                            ),
                          ),
                        ),
                      if (clientCode.isNotEmpty)
                        const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          dateStr,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '₹${amount is num ? amount.toStringAsFixed(2) : amount}',
              style: GoogleFonts.merriweather(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD35D16),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 22),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Delete Transaction',
              onPressed: () => _confirmDeleteTransaction(
                  txn['transaction_uuid']?.toString()),
            ),
          ],
        ),
      ),
    );
  }
}
