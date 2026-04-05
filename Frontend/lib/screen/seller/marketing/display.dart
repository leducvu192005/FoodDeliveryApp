import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../services/auth_services.dart';

class SellerDisplayScreen extends StatefulWidget {
  const SellerDisplayScreen({super.key});

  @override
  State<SellerDisplayScreen> createState() => _SellerDisplayScreenState();
}

class _SellerDisplayScreenState extends State<SellerDisplayScreen> {
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
        Uri.parse(ApiConfig.path('/display/seller/programs')),
        headers: await _headers(),
      );
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        if (mounted) {
          setState(() => _programs = data.cast<Map<String, dynamic>>());
        }
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

  Future<void> _joinProgram(int programId) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.path('/display/seller/programs/$programId/join')),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['detail'] ?? 'Tham gia thanh cong'),
              backgroundColor: Colors.green),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['detail'] ?? 'Loi'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    }
  }

  Future<void> _leaveProgram(int programId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xac nhan'),
        content: const Text('Ban co chac muon roi chuong trinh nay?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Roi', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.path('/display/seller/programs/$programId/leave')),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['detail'] ?? 'Da roi'),
              backgroundColor: Colors.orange),
        );
        _load();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['detail'] ?? 'Loi'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    }
  }

  Future<void> _openDishSelector(int programId) async {
    try {
      final res = await http.get(
        Uri.parse(
            ApiConfig.path('/display/seller/programs/$programId/my-dishes')),
        headers: await _headers(),
      );
      if (res.statusCode != 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Loi tai danh sach mon'),
                backgroundColor: Colors.red),
          );
        }
        return;
      }

      final data = jsonDecode(res.body);
      final List<dynamic> allDishes = data['dishes'] ?? [];
      final List<int> selectedIds = List<int>.from(data['selected_ids'] ?? []);

      if (!mounted) return;

      final result = await Navigator.push<List<int>>(
        context,
        MaterialPageRoute(
          builder: (_) => _DishSelectorScreen(
            dishes: allDishes.cast<Map<String, dynamic>>(),
            initialSelected: selectedIds,
          ),
        ),
      );

      if (result == null) return;

      // Save selected dishes
      final saveRes = await http.put(
        Uri.parse(
            ApiConfig.path('/display/seller/programs/$programId/dish-show')),
        headers: await _headers(),
        body: jsonEncode({'dish_ids': result}),
      );
      final saveData = jsonDecode(saveRes.body);
      if (saveRes.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(saveData['detail'] ?? 'Da luu'),
                backgroundColor: Colors.green),
          );
        }
        _load();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(saveData['detail'] ?? 'Loi'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Loi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuong trinh hien thi'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? const Center(child: Text('Chua co chuong trinh nao'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _programs.length,
                    itemBuilder: (context, index) {
                      final p = _programs[index];
                      final type = p['program_type'] ?? 'featured';
                      final isJoined = p['is_joined'] == true;
                      final rawDishShow = p['dish_show'];
                      final dishShow = rawDishShow is List
                          ? List<int>.from(rawDishShow)
                          : rawDishShow is String && rawDishShow.isNotEmpty
                              ? List<int>.from(jsonDecode(rawDishShow))
                              : <int>[];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _typeIcons[type] ?? Icons.star,
                                      color: Colors.deepOrange,
                                      size: 28,
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
                                              fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _typeLabels[type] ?? type,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700]),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isJoined)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.green.withAlpha(80)),
                                      ),
                                      child: const Text(
                                        'Da tham gia',
                                        style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11),
                                      ),
                                    ),
                                ],
                              ),
                              if (p['description'] != null &&
                                  p['description'].toString().isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(p['description'],
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 13)),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.store,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p['seller_count'] ?? 0} quan'
                                    '${p['max_sellers'] != null && p['max_sellers'] > 0 ? ' / ${p['max_sellers']}' : ''}',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.calendar_today,
                                      size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatDate(p['start_date'])} - ${_formatDate(p['end_date'])}',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                              if (isJoined) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.restaurant_menu,
                                          size: 14, color: Colors.blue[700]),
                                      const SizedBox(width: 6),
                                      Text(
                                        dishShow.isEmpty
                                            ? 'Chua chon mon hien thi'
                                            : 'Da chon ${dishShow.length} mon hien thi',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue[700]),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (isJoined)
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () =>
                                            _openDishSelector(p['id']),
                                        icon: const Icon(Icons.checklist,
                                            size: 18),
                                        label: const Text('Chon mon'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _leaveProgram(p['id']),
                                        icon: const Icon(Icons.exit_to_app,
                                            size: 18),
                                        label: const Text('Roi'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                              color: Colors.red),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _joinProgram(p['id']),
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 18),
                                    label: const Text('Tham gia'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepOrange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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

/// Screen to select dishes for a display program
class _DishSelectorScreen extends StatefulWidget {
  final List<Map<String, dynamic>> dishes;
  final List<int> initialSelected;

  const _DishSelectorScreen({
    required this.dishes,
    required this.initialSelected,
  });

  @override
  State<_DishSelectorScreen> createState() => _DishSelectorScreenState();
}

class _DishSelectorScreenState extends State<_DishSelectorScreen> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<int>.from(widget.initialSelected);
  }

  void _toggleDish(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chon mon hien thi'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selected.toList()),
            child: const Text('Luu',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: widget.dishes.isEmpty
          ? const Center(child: Text('Ban chua co mon nao'))
          : Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.blue.withAlpha(15),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Da chon ${_selected.length}/${widget.dishes.length} mon',
                          style:
                              TextStyle(fontSize: 13, color: Colors.blue[700]),
                        ),
                      ),
                      if (_selected.length < widget.dishes.length)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selected = widget.dishes
                                  .map((d) => d['id'] as int)
                                  .toSet();
                            });
                          },
                          child: const Text('Chon tat ca',
                              style: TextStyle(fontSize: 12)),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            setState(() => _selected.clear());
                          },
                          child: const Text('Bo chon tat ca',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.dishes.length,
                    itemBuilder: (context, index) {
                      final dish = widget.dishes[index];
                      final id = dish['id'] as int;
                      final isSelected = _selected.contains(id);

                      return ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildDishImage(dish['img']),
                          ),
                        ),
                        title: Text(
                          dish['name'] ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          '${_formatPrice(dish['price'])}d',
                          style: TextStyle(
                              color: Colors.deepOrange[700], fontSize: 13),
                        ),
                        trailing: Checkbox(
                          value: isSelected,
                          activeColor: Colors.deepOrange,
                          onChanged: (_) => _toggleDish(id),
                        ),
                        onTap: () => _toggleDish(id),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDishImage(String? img) {
    if (img != null && img.startsWith('data:image')) {
      try {
        final base64Str = img.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    if (img != null && img.startsWith('http')) {
      return Image.network(img,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(Icons.restaurant, color: Colors.grey[400]),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0';
    final p =
        (price is num) ? price.toInt() : int.tryParse(price.toString()) ?? 0;
    final s = p.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
