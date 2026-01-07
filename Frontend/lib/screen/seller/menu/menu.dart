import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'category.dart';
import 'dish.dart';
import 'edit_dish.dart';
import 'topping.dart';
import '../../../config/api_config.dart';

class MenuScreen extends StatefulWidget {
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  List<Map<String, dynamic>> _categories = [];
  Map<int, List<Map<String, dynamic>>> _dishesByCategory = {};
  Map<int, bool> _expandedCategories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categoryResponse = await http.get(Uri.parse(ApiConfig.categoryUrl));

      if (categoryResponse.statusCode == 200) {
        final List<dynamic> categoryData = json.decode(categoryResponse.body);
        _categories = categoryData.cast<Map<String, dynamic>>();

        final dishResponse = await http.get(Uri.parse(ApiConfig.dishUrl));

        if (dishResponse.statusCode == 200) {
          final List<dynamic> dishData = json.decode(dishResponse.body);

          _dishesByCategory.clear();
          for (var dish in dishData) {
            int categoryId = dish['category_id'];
            if (!_dishesByCategory.containsKey(categoryId)) {
              _dishesByCategory[categoryId] = [];
            }
            _dishesByCategory[categoryId]!.add(dish);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải dữ liệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- GIỮ NGUYÊN CÁC HÀM CŨ CỦA BẠN ---
  Future<void> _deleteDish(int dishId, String dishName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa món "$dishName"?'),
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
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.dishUrl}$dishId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa món thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteCategory(int categoryId, String categoryName) async {
    final dishes = _dishesByCategory[categoryId] ?? [];
    if (dishes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa danh mục có món.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa danh mục "$categoryName"?'),
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
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.categoryUrl}$categoryId'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa danh mục thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDishOptions(BuildContext context, Map<String, dynamic> dish) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Sửa món'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditDish(dish: dish)),
                );
                if (result == true) _loadData();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Xóa món', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteDish(dish['id'], dish['name']);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Thực đơn',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.help_outline, color: Colors.black),
              onPressed: () {},
            ),
          ],
          // --- THÊM PHẦN TAB TẠI ĐÂY ---
          bottom: TabBar(
            indicatorColor: Colors.teal[900],
            indicatorWeight: 3,
            labelColor: Colors.teal[900],
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Món'),
              Tab(text: 'Tuỳ chọn nhóm'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDishTabContent(), // Nội dung tab Món (giữ nguyên logic cũ)
            _buildOptionGroupTabContent(), // Nội dung tab Tùy chọn nhóm
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _showAddOptions(context);
          },
          backgroundColor: Colors.teal[900],
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  // --- TÁCH PHẦN HIỂN THỊ MÓN RA ĐỂ BỎ VÀO TAB ---
  Widget _buildDishTabContent() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // _buildFilterChip(Icons.search, 'Tìm kiếm'),
              // SizedBox(width: 8),
              // _buildFilterChip(null, 'Hết hàng (1)'),
              // SizedBox(width: 8),
              // _buildFilterChip(Icons.access_time, 'Lịch bán'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _categories.isEmpty
              ? Center(child: Text('Chưa có danh mục nào'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final categoryId = category['id'];
                      final dishes = _dishesByCategory[categoryId] ?? [];
                      final isExpanded =
                          _expandedCategories[categoryId] ?? false;

                      return Column(
                        children: [
                          ListTile(
                            title: Text(
                              category['name'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${dishes.length} món'),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: Colors.teal,
                            ),
                            onTap: () {
                              setState(() {
                                _expandedCategories[categoryId] = !isExpanded;
                              });
                            },
                            onLongPress: () {
                              // logic xóa danh mục giữ nguyên...
                              _showCategoryOptions(
                                categoryId,
                                category['name'],
                              );
                            },
                          ),
                          if (isExpanded)
                            ...dishes
                                .map((dish) => _buildDishItem(dish))
                                .toList(),
                          Divider(height: 1),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // Nội dung Tab Tùy chọn nhóm
  Widget _buildOptionGroupTabContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có nhóm tùy chọn nào',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- GIỮ NGUYÊN CÁC WIDGET PHỤ TRỢ ---
  void _showCategoryOptions(int categoryId, String name) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListTile(
        leading: Icon(Icons.delete, color: Colors.red),
        title: Text('Xóa danh mục', style: TextStyle(color: Colors.red)),
        onTap: () {
          Navigator.pop(context);
          _deleteCategory(categoryId, name);
        },
      ),
    );
  }

  Widget _buildDishItem(Map<String, dynamic> dish) {
    return Container(
      color: Colors.grey[50],
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        leading: dish['img'] != null && dish['img'].toString().isNotEmpty
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(
                      base64Decode(dish['img'].toString().split(',').last),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.restaurant, color: Colors.grey[600]),
              ),
        title: Text(dish['name']),
        subtitle: Text(
          '${dish['price']}đ',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onPressed: () => _showDishOptions(context, dish),
        ),
        onTap: () => _showDishOptions(context, dish),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.category, color: Colors.teal[900]),
              title: Text('Thêm danh mục'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddCategory()),
                );
                if (result == true) _loadData();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.restaurant_menu, color: Colors.teal[900]),
              title: Text('Thêm món'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddDish()),
                );
                if (result == true) _loadData();
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.add_box, color: Colors.teal[900]),
              title: Text('Thêm nhóm Topping'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddToppingGroupScreen(),
                  ),
                );
                if (result == true) _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(IconData? icon, String label) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 16, color: Colors.grey[700]),
            if (icon != null) SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[800]),
            ),
          ],
        ),
      ),
    );
  }
}
