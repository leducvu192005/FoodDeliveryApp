import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../services/auth_services.dart';

class ToppingScreen extends StatefulWidget {
  final Map<String, dynamic>? topping; // null = thêm mới, có giá trị = sửa

  const ToppingScreen({super.key, this.topping});

  @override
  _ToppingScreenState createState() => _ToppingScreenState();
}

class _ToppingScreenState extends State<ToppingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  List<Map<String, dynamic>> _items =
      []; // Danh sách các item trong nhóm topping
  List<Map<String, dynamic>> _allDishes = []; // Danh sách tất cả món ăn
  List<int> _selectedDishIds = []; // ID các món đã chọn

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDishes();

    // Nếu đang sửa, load dữ liệu topping
    if (widget.topping != null) {
      _nameController.text = widget.topping!['name'] ?? '';
      _minController.text = widget.topping!['min']?.toString() ?? '0';
      _maxController.text = widget.topping!['max']?.toString() ?? '1';
      _items = List<Map<String, dynamic>>.from(widget.topping!['items'] ?? []);
      _selectedDishIds = List<int>.from(widget.topping!['dish_ids'] ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  // ========== TẢI DANH SÁCH MÓN ĂN ==========
  Future<void> _loadDishes() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.dishUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allDishes = data.cast<Map<String, dynamic>>();
        });
      } else if (response.statusCode == 401) {
        throw Exception('Đã hết phiên đăng nhập');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Lỗi tải danh sách món: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ========== HIỂN THỊ DIALOG THÊM TOPPING ITEM ==========
  void _showAddToppingItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm tùy chọn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên tùy chọn *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Giá *',
                border: OutlineInputBorder(),
                suffixText: 'đ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                setState(() {
                  _items.add({
                    'name': nameController.text,
                    'price': int.tryParse(priceController.text) ?? 0,
                  });
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                );
              }
            },
            child: Text('Thêm'),
          ),
        ],
      ),
    );
  }

  // ========== HIỂN THỊ DIALOG SỬA TOPPING ITEM ==========
  void _showEditToppingItemDialog(int index) {
    final item = _items[index];
    final nameController = TextEditingController(text: item['name']);
    final priceController =
        TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sửa tùy chọn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên tùy chọn *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: InputDecoration(
                labelText: 'Giá *',
                border: OutlineInputBorder(),
                suffixText: 'đ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                setState(() {
                  _items[index] = {
                    'name': nameController.text,
                    'price': int.tryParse(priceController.text) ?? 0,
                  };
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')),
                );
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ========== XÓA TOPPING ITEM ==========
  void _deleteToppingItem(int index) async {
    final item = _items[index];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa tùy chọn "${item['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _items.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa tùy chọn'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ========== HIỂN THỊ DIALOG CHỌN MÓN ÁP DỤNG ==========
  void _showSelectDishesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn món áp dụng'),
        content: SizedBox(
          width: double.maxFinite,
          child: _allDishes.isEmpty
              ? Center(child: Text('Chưa có món nào'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allDishes.length,
                  itemBuilder: (context, index) {
                    final dish = _allDishes[index];
                    final dishId = dish['id'];
                    final isSelected = _selectedDishIds.contains(dishId);

                    return CheckboxListTile(
                      title: Text(dish['name']),
                      subtitle: Text('${dish['price']}đ'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedDishIds.add(dishId);
                          } else {
                            _selectedDishIds.remove(dishId);
                          }
                        });
                        Navigator.pop(context);
                        _showSelectDishesDialog(); // Refresh dialog
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ========== LƯU TOPPING ==========
  Future<void> _saveTopping() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng thêm ít nhất 1 tùy chọn')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      final data = {
        'name': _nameController.text,
        'min': int.tryParse(_minController.text) ?? 0,
        'max': int.tryParse(_maxController.text) ?? 1,
        'items': _items,
        'dish_ids': _selectedDishIds,
      };

      final response = widget.topping == null
          ? await http.post(
              Uri.parse(ApiConfig.toppingUrl),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(data),
            )
          : await http.put(
              Uri.parse('${ApiConfig.toppingUrl}${widget.topping!['id']}'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(data),
            );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.topping == null
                ? 'Thêm nhóm topping thành công'
                : 'Cập nhật nhóm topping thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Lỗi: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ========== XÓA TOPPING ==========
  Future<void> _deleteTopping() async {
    // Hiển thị dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text(
            'Bạn có chắc muốn xóa nhóm topping "${_nameController.text}"?\n\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.toppingUrl}${widget.topping!['id']}'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa nhóm topping thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Trả về true để reload data
      } else {
        throw Exception('Lỗi: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.topping != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa nhóm topping' : 'Thêm nhóm topping'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // ===== TÊN NHÓM TOPPING =====
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên nhóm topping *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên nhóm topping';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // ===== MIN/MAX =====
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minController,
                    decoration: InputDecoration(
                      labelText: 'Tối thiểu',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxController,
                    decoration: InputDecoration(
                      labelText: 'Tối đa',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // ===== DANH SÁCH CÁC TÙY CHỌN =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh sách tùy chọn (${_items.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddToppingItemDialog,
                  icon: Icon(Icons.add),
                  label: Text('Thêm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal[900],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Hiển thị các item với nút sửa/xóa
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.teal[900],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    item['name'],
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    '+${item['price']}đ',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút sửa
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditToppingItemDialog(index),
                        tooltip: 'Sửa',
                      ),
                      // Nút xóa
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteToppingItem(index),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              );
            }),

            SizedBox(height: 24),

            // ===== CHỌN MÓN ÁP DỤNG =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Áp dụng cho món (${_selectedDishIds.length})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showSelectDishesDialog,
                  icon: Icon(Icons.restaurant_menu),
                  label: Text('Chọn món'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Hiển thị các món đã chọn
            ..._selectedDishIds.map((dishId) {
              final dish = _allDishes.firstWhere(
                (d) => d['id'] == dishId,
                orElse: () => {'name': 'Không tìm thấy', 'price': 0},
              );
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text(dish['name']),
                  subtitle: Text('${dish['price']}đ'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _selectedDishIds.remove(dishId);
                      });
                    },
                  ),
                ),
              );
            }),

            SizedBox(height: 32),

            // ===== NÚT LƯU/CẬP NHẬT =====
            ElevatedButton(
              onPressed: _isLoading ? null : _saveTopping,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[900],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEdit ? 'Cập nhật' : 'Thêm mới',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),

            // ===== NÚT XÓA (CHỈ HIỆN KHI ĐANG SỬA) =====
            if (isEdit) ...[
              SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _deleteTopping,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Xóa nhóm topping',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
