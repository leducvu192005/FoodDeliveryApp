import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../services/auth_services.dart';

class AdminDisplayScreen extends StatefulWidget {
  const AdminDisplayScreen({super.key});

  @override
  State<AdminDisplayScreen> createState() => _AdminDisplayScreenState();
}

class _AdminDisplayScreenState extends State<AdminDisplayScreen> {
  List<Map<String, dynamic>> _programs = [];
  bool _loading = true;

  static const _typeLabels = {
    'featured': 'Noi bat',
    'flash_sale': 'Flash Sale',
    'top_rated': 'Top danh gia',
    'promotion': 'Khuyen mai',
  };

  static const _typeIcons = {
    'featured': Icons.star,
    'flash_sale': Icons.flash_on,
    'top_rated': Icons.thumb_up,
    'promotion': Icons.local_offer,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(ApiConfig.path('/display/programs')),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted)
          setState(() => _programs = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteProgram(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xac nhan'),
        content: const Text('Ban co chac muon xoa chuong trinh nay?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await http.delete(
        Uri.parse(ApiConfig.path('/display/programs/$id')),
        headers: await _headers(),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> program) async {
    try {
      await http.put(
        Uri.parse(ApiConfig.path('/display/programs/${program['id']}')),
        headers: await _headers(),
        body: jsonEncode({'is_active': !(program['is_active'] == true)}),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    }
  }

  void _openCreateDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final maxCtrl = TextEditingController(text: '0');
    String selectedType = 'featured';
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tao chuong trinh moi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ten chuong trinh *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mo ta',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Loai chuong trinh',
                    border: OutlineInputBorder(),
                  ),
                  items: _typeLabels.entries
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: maxCtrl,
                  decoration: const InputDecoration(
                    labelText: 'So quan toi da (0 = khong gioi han)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(startDate == null
                      ? 'Chon ngay bat dau *'
                      : 'Bat dau: ${startDate!.toLocal().toString().substring(0, 16)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDialogState(() => startDate = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(endDate == null
                      ? 'Chon ngay ket thuc *'
                      : 'Ket thuc: ${endDate!.toLocal().toString().substring(0, 16)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: startDate ?? DateTime.now(),
                      firstDate: startDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDialogState(() => endDate = d);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE67E22)),
              onPressed: () async {
                if (titleCtrl.text.isEmpty ||
                    startDate == null ||
                    endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Vui long nhap day du thong tin')),
                  );
                  return;
                }
                try {
                  await http.post(
                    Uri.parse(ApiConfig.path('/display/programs')),
                    headers: await _headers(),
                    body: jsonEncode({
                      'title': titleCtrl.text,
                      'description': descCtrl.text,
                      'program_type': selectedType,
                      'start_date': startDate!.toIso8601String(),
                      'end_date': endDate!.toIso8601String(),
                      'max_sellers': int.tryParse(maxCtrl.text) ?? 0,
                    }),
                  );
                  if (mounted) Navigator.pop(ctx);
                  _load();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Loi: $e')),
                  );
                }
              },
              child: const Text('Tao', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _viewSellers(Map<String, dynamic> program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ProgramSellersScreen(
            programId: program['id'], title: program['title']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFE67E22);

    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Chuong trinh hien thi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openCreateDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tao moi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _programs.isEmpty
              ? const Center(child: Text('Chua co chuong trinh nao'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _programs.length,
                    itemBuilder: (context, index) {
                      final p = _programs[index];
                      final type = p['program_type'] ?? 'featured';
                      final isActive = p['is_active'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accent.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _typeIcons[type] ?? Icons.star,
                                      color: accent,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _typeLabels[type] ?? type,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    activeColor: accent,
                                    onChanged: (_) => _toggleActive(p),
                                  ),
                                ],
                              ),
                              if (p['description'] != null &&
                                  p['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(p['description'],
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 13)),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.store,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p['seller_count'] ?? 0} quan tham gia'
                                    '${p['max_sellers'] != null && p['max_sellers'] > 0 ? ' / ${p['max_sellers']} toi da' : ''}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_formatDate(p['start_date'])} - ${_formatDate(p['end_date'])}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _viewSellers(p),
                                    icon: const Icon(Icons.people, size: 16),
                                    label: const Text('Xem quan',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _deleteProgram(p['id']),
                                    icon: const Icon(Icons.delete,
                                        size: 16, color: Colors.red),
                                    label: const Text('Xoa',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.red)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '?';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

// ==================== Xem danh sách quán trong chương trình ====================
class _ProgramSellersScreen extends StatefulWidget {
  final int programId;
  final String title;
  const _ProgramSellersScreen({required this.programId, required this.title});

  @override
  State<_ProgramSellersScreen> createState() => _ProgramSellersScreenState();
}

class _ProgramSellersScreenState extends State<_ProgramSellersScreen> {
  List<Map<String, dynamic>> _sellers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(
        Uri.parse(
            ApiConfig.path('/display/programs/${widget.programId}/sellers')),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted)
          setState(() => _sellers = data.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E22),
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sellers.isEmpty
              ? const Center(child: Text('Chua co quan nao tham gia'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sellers.length,
                  itemBuilder: (context, index) {
                    final s = _sellers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFE0B2),
                          child: Icon(Icons.store, color: Color(0xFFE67E22)),
                        ),
                        title: Text(s['seller_name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle:
                            Text(s['seller_address'] ?? 'Chua co dia chi'),
                        trailing: Text(
                          _formatDate(s['joined_at']),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr);
      return '${d.day}/${d.month}';
    } catch (_) {
      return '';
    }
  }
}
