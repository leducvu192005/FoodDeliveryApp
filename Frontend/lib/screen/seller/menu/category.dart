// Frontend/lib/screen/seller/menu/category.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';
import '../../../services/auth_services.dart';

// ==================== SCREEN CHÍNH: QUẢN LÝ DANH MỤC ====================
class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({Key? key}) : super(key: key);

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // ==================== 📥 LOAD DANH SÁCH CATEGORY ====================
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.categoryUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _categories = data.cast<Map<String, dynamic>>();
        });
      } else if (response.statusCode == 401) {
        throw Exception('Đã hết phiên đăng nhập');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== ➕ THÊM CATEGORY MỚI ====================
  Future<void> _addCategory() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CategoryDialog(
        title: 'Thêm danh mục',
        initialName: '',
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final token = await AuthService.getToken();
        if (token == null) {
          throw Exception('Đã hết phiên đăng nhập');
        }

        final response = await http.post(
          Uri.parse(ApiConfig.categoryUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'name': result}),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Thêm danh mục thành công'),
                backgroundColor: Colors.green,
              ),
            );
            _loadCategories(); // Reload danh sách
          }
        } else {
          final error = json.decode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error['detail'] ?? 'Có lỗi xảy ra'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================== ✏️ SỬA CATEGORY ====================
  Future<void> _editCategory(Map<String, dynamic> category) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _CategoryDialog(
        title: 'Sửa danh mục',
        initialName: category['name'],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        final token = await AuthService.getToken();
        if (token == null) {
          throw Exception('Đã hết phiên đăng nhập');
        }

        final response = await http.put(
          Uri.parse('${ApiConfig.categoryUrl}${category['id']}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode({'name': result}),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cập nhật danh mục thành công'),
                backgroundColor: Colors.green,
              ),
            );
            _loadCategories(); // Reload danh sách
          }
        } else {
          final error = json.decode(response.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error['detail'] ?? 'Có lỗi xảy ra'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi kết nối: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==================== 🗑️ XÓA CATEGORY ====================
  Future<void> _deleteCategory(int categoryId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa danh mục "$name"?'),
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
        Uri.parse('${ApiConfig.categoryUrl}$categoryId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Xóa danh mục thành công'),
              backgroundColor: Colors.green,
            ),
          );
          _loadCategories(); // Reload danh sách
        }
      } else {
        final error = json.decode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error['detail'] ?? 'Có lỗi xảy ra'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi kết nối: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==================== 🎨 BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý danh mục',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () =>
              Navigator.pop(context, true), // ✅ Return true để reload
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Chưa có danh mục nào',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _addCategory,
                        icon: Icon(Icons.add),
                        label: Text('Thêm danh mục đầu tiên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal[900],
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal[100],
                          child: Icon(Icons.category, color: Colors.teal[900]),
                        ),
                        title: Text(
                          category['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text('ID: ${category['id']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✏️ NÚT SỬA
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editCategory(category),
                              tooltip: 'Sửa',
                            ),
                            // 🗑️ NÚT XÓA
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteCategory(
                                category['id'],
                                category['name'],
                              ),
                              tooltip: 'Xóa',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      // ➕ NÚT THÊM FLOATING
      floatingActionButton: _categories.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addCategory,
              backgroundColor: Colors.teal[900],
              child: Icon(Icons.add),
              tooltip: 'Thêm danh mục',
            )
          : null,
    );
  }
}

// ==================== 💬 DIALOG NHẬP TÊN CATEGORY ====================
class _CategoryDialog extends StatefulWidget {
  final String title;
  final String initialName;

  const _CategoryDialog({
    required this.title,
    required this.initialName,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Tên danh mục',
          hintText: 'VD: Đồ uống',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (value) {
          if (value.trim().isNotEmpty) {
            Navigator.pop(context, value.trim());
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[900],
          ),
          child: Text('Lưu'),
        ),
      ],
    );
  }
}

//  widget nhỏ gọn hơn trong menu
class AddCategory extends StatelessWidget {
  const AddCategory({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CategoryManagementScreen();
  }
}
