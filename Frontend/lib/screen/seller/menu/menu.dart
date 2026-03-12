import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'category.dart';
import 'dish.dart'; // File đã gộp add + edit
import 'topping.dart'; // File đã gộp add + edit
import '../../../config/api_config.dart';
import '../../../services/auth_services.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});
  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen>
    with SingleTickerProviderStateMixin {
  // ========== KHAI BÁO BIẾN ==========
  List<Map<String, dynamic>> _categories = []; // Danh sách danh mục
  final Map<int, List<Map<String, dynamic>>> _dishesByCategory =
      {}; // Món ăn theo danh mục
  final Map<int, bool> _expandedCategories =
      {}; // Trạng thái mở/đóng của danh mục
  List<Map<String, dynamic>> _toppings = []; // Danh sách nhóm topping
  bool _isLoading = true; // Trạng thái đang tải dữ liệu

  TabController? _tabController; // Controller cho tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(); // Load dữ liệu khi khởi tạo
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  // ========== TẢI DỮ LIỆU TỪ API ==========
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      final headers = {'Authorization': 'Bearer $token'};

      // Tải danh sách danh mục
      final categoryResponse = await http.get(
        Uri.parse(ApiConfig.categoryUrl),
        headers: headers,
      );

      if (categoryResponse.statusCode == 200) {
        final List<dynamic> categoryData = json.decode(categoryResponse.body);
        _categories = categoryData.cast<Map<String, dynamic>>();

        // Tải danh sách món ăn
        final dishResponse = await http.get(
          Uri.parse(ApiConfig.dishUrl),
          headers: headers,
        );

        if (dishResponse.statusCode == 200) {
          final List<dynamic> dishData = json.decode(dishResponse.body);
          final categoryIds = _categories.map((c) => c['id'] as int).toSet();

          // Phân loại món ăn theo danh mục (chỉ món thuộc danh mục của quán)
          _dishesByCategory.clear();
          for (var dish in dishData) {
            int categoryId = dish['category_id'];
            if (categoryIds.contains(categoryId)) {
              if (!_dishesByCategory.containsKey(categoryId)) {
                _dishesByCategory[categoryId] = [];
              }
              _dishesByCategory[categoryId]!.add(dish);
            }
          }
        }
      }

      // Tải danh sách nhóm topping
      final toppingResponse = await http.get(
        Uri.parse(ApiConfig.toppingUrl),
        headers: headers,
      );
      if (toppingResponse.statusCode == 200) {
        final List<dynamic> toppingData = json.decode(toppingResponse.body);
        _toppings = toppingData.cast<Map<String, dynamic>>();
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

  // ========== XÓA MÓN ĂN ==========
  Future<void> _deleteDish(int dishId, String dishName) async {
    // Hiển thị dialog xác nhận
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
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      // Gọi API xóa món
      final response = await http.delete(
        Uri.parse('${ApiConfig.dishUrl}$dishId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa món thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Tải lại dữ liệu
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ========== XÓA DANH MỤC ==========
  Future<void> _deleteCategory(int categoryId, String categoryName) async {
    // Kiểm tra xem danh mục có món ăn không
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

    // Hiển thị dialog xác nhận
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
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      // Gọi API xóa danh mục
      final response = await http.delete(
        Uri.parse('${ApiConfig.categoryUrl}$categoryId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa danh mục thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Tải lại dữ liệu
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ========== XÓA NHÓM TOPPING ==========
  Future<void> _deleteTopping(int toppingId, String toppingName) async {
    // Hiển thị dialog xác nhận
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhóm topping "$toppingName"?'),
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
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Đã hết phiên đăng nhập');
      }

      // Gọi API xóa topping
      final response = await http.delete(
        Uri.parse('${ApiConfig.toppingUrl}$toppingId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xóa nhóm topping thành công'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData(); // Tải lại dữ liệu
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ========== HIỂN THỊ TÙY CHỌN CHO MÓN ĂN (SỬA/XÓA) ==========
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
            // ===== NÚT SỬA MÓN =====
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Sửa món'),
              onTap: () async {
                Navigator.pop(context);
                // Mở màn hình DishScreen với dish để sửa
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DishScreen(dish: dish), // Truyền dish = chế độ sửa
                  ),
                );
                if (result == true) _loadData(); // Tải lại nếu có thay đổi
              },
            ),
            Divider(),
            // ===== NÚT XÓA MÓN =====
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Xóa món', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteDish(dish['id'], dish['name']); // Gọi hàm xóa
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== HIỂN THỊ TÙY CHỌN CHO DANH MỤC (XÓA) ==========
  void _showCategoryOptions(int categoryId, String name) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListTile(
        leading: Icon(Icons.delete, color: Colors.red),
        title: Text('Xóa danh mục', style: TextStyle(color: Colors.red)),
        onTap: () {
          Navigator.pop(context);
          _deleteCategory(categoryId, name); // Gọi hàm xóa
        },
      ),
    );
  }

  // ========== CHUYỂN ĐẾN MÀN HÌNH QUẢN LÝ DANH MỤC ==========
  void _navigateToEditCategories() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryManagementScreen(),
      ),
    );

    if (result == true) {
      _loadData(); // Tải lại dữ liệu nếu có thay đổi
    }
  }

  // ========== HIỂN THỊ DIALOG SẮP XẾP DANH MỤC ==========
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sắp xếp'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sắp xếp A-Z
            ListTile(
              leading: Icon(Icons.sort_by_alpha, color: Colors.teal),
              title: Text('Theo tên A-Z'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _categories.sort((a, b) =>
                      a['name'].toString().compareTo(b['name'].toString()));
                });
              },
            ),
            Divider(),
            // Sắp xếp Z-A
            ListTile(
              leading: Icon(Icons.sort, color: Colors.teal),
              title: Text('Theo tên Z-A'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _categories.sort((a, b) =>
                      b['name'].toString().compareTo(a['name'].toString()));
                });
              },
            ),
            Divider(),
            // Sắp xếp theo ID
            ListTile(
              leading: Icon(Icons.numbers, color: Colors.teal),
              title: Text('Theo ID'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _categories.sort((a, b) => a['id'].compareTo(b['id']));
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== XÂY DỰNG CÁC NÚT FLOATING (CHỈNH SỬA, SẮP XẾP, THÊM) ==========
  // ========== XÂY DỰNG CÁC NÚT FLOATING (CHỈNH SỬA, SẮP XẾP, THÊM) ==========
  Widget _buildFloatingButtons() {
    final isOnDishTab = _tabController?.index == 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Nút chỉnh sửa danh mục (chỉ hiện ở tab món, màu xanh dương, mini)
        if (isOnDishTab)
          FloatingActionButton(
            heroTag: 'edit_categories',
            onPressed: _navigateToEditCategories,
            backgroundColor: Colors.blue,
            mini: true,
            child: Icon(Icons.edit, color: Colors.white),
          ),
        if (isOnDishTab) SizedBox(height: 12),

        // Nút sắp xếp (chỉ hiện ở tab món, màu cam, mini)
        if (isOnDishTab)
          FloatingActionButton(
            heroTag: 'sort',
            onPressed: _showSortDialog,
            backgroundColor: Colors.orange,
            mini: true,
            child: Icon(Icons.sort, color: Colors.white),
          ),
        if (isOnDishTab) SizedBox(height: 12),

        // Nút thêm chính (màu xanh lá, kích thước bình thường)
        FloatingActionButton(
          heroTag: 'add',
          onPressed: () {
            // Kiểm tra tab hiện tại để hiển thị options phù hợp
            if (isOnDishTab) {
              _showAddOptionsForDishTab(context); // Tab món ăn
            } else {
              _showAddOptionsForToppingTab(context); // Tab topping
            }
          },
          backgroundColor: Colors.teal[900],
          child: Icon(Icons.add, color: Colors.white),
        ),
      ],
    );
  }

  // ========== XÂY DỰNG GIAO DIỆN CHÍNH ==========
  // ========== XÂY DỰNG GIAO DIỆN CHÍNH ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thực đơn',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal[900],
          indicatorWeight: 3,
          labelColor: Colors.teal[900],
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            setState(() {}); // Rebuild để cập nhật floating buttons
          },
          tabs: [
            Tab(text: 'Món'), // Tab danh sách món
            Tab(text: 'Tuỳ chọn nhóm'), // Tab danh sách topping
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDishTabContent(), // Nội dung tab món
          _buildOptionGroupTabContent(), // Nội dung tab topping
        ],
      ),
      floatingActionButton: _buildFloatingButtons(), // Các nút floating
    );
  }

  // ========== NỘI DUNG TAB MÓN ĂN ==========
  Widget _buildDishTabContent() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator()) // Đang tải
              : _categories.isEmpty
                  ? Center(
                      child: Text('Chưa có danh mục nào')) // Không có dữ liệu
                  : RefreshIndicator(
                      onRefresh: _loadData, // Kéo để refresh
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
                              // Hiển thị danh mục
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
                                  // Mở/đóng danh sách món trong danh mục
                                  setState(() {
                                    _expandedCategories[categoryId] =
                                        !isExpanded;
                                  });
                                },
                                onLongPress: () {
                                  // Nhấn giữ để hiển thị options xóa danh mục
                                  _showCategoryOptions(
                                      categoryId, category['name']);
                                },
                              ),
                              // Hiển thị danh sách món nếu được mở rộng
                              if (isExpanded)
                                ...dishes.map((dish) => _buildDishItem(dish)),
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

  // ========== NỘI DUNG TAB TOPPING ==========
  // ========== NỘI DUNG TAB TOPPING (CLICK VÀO ĐỂ CHỈNH SỬA) ==========
  Widget _buildOptionGroupTabContent() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator()); // Đang tải
    }

    if (_toppings.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadData, // Kéo để refresh
      child: ListView.builder(
        itemCount: _toppings.length,
        itemBuilder: (context, index) {
          final topping = _toppings[index];
          final items = topping['items'] as List? ?? [];

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.teal[100],
                child: Icon(Icons.add_box, color: Colors.teal[900]),
              ),
              title: Text(
                topping['name'] ?? 'Không tên',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${items.length} tùy chọn'),
              // ===== BỎ TRAILING (NÚT 3 CHẤM) =====
              // ===== CLICK VÀO ĐỂ CHỈNH SỬA =====
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ToppingScreen(topping: topping), // Mở màn hình sửa
                  ),
                );
                if (result == true) _loadData(); // Tải lại nếu có thay đổi
              },
              // ===== NHẤN GIỮ ĐỂ XÓA =====
              onLongPress: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Xác nhận xóa'),
                    content: Text(
                        'Bạn có chắc muốn xóa nhóm topping "${topping['name']}"?'),
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
                  _deleteTopping(topping['id'], topping['name']);
                }
              },
            ),
          );
        },
      ),
    );
  }

  // ========== HIỂN THỊ TỪNG MÓN ĂN ==========
  Widget _buildDishItem(Map<String, dynamic> dish) {
    return Container(
      color: Colors.grey[50],
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
        // Hiển thị ảnh món
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
        title: Text(dish['name']), // Tên món
        subtitle: Text(
          '${dish['price']}đ', // Giá món
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: Colors.grey),
          onPressed: () => _showDishOptions(context, dish), // Hiển thị options
        ),
        onTap: () => _showDishOptions(context, dish),
      ),
    );
  }

  // ========== HIỂN THỊ OPTIONS THÊM MÓN/DANH MỤC ==========
  void _showAddOptionsForDishTab(BuildContext context) {
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
            // ===== NÚT QUẢN LÝ DANH MỤC =====
            ListTile(
              leading: Icon(Icons.category, color: Colors.teal[900]),
              title: Text('Quản lý danh mục'),
              onTap: () {
                Navigator.pop(context);
                _navigateToEditCategories();
              },
            ),
            Divider(),
            // ===== NÚT THÊM MÓN =====
            ListTile(
              leading: Icon(Icons.restaurant_menu, color: Colors.teal[900]),
              title: Text('Thêm món'),
              onTap: () async {
                Navigator.pop(context);
                // Mở màn hình DishScreen không truyền dish = chế độ thêm mới
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DishScreen()),
                );
                if (result == true) _loadData(); // Tải lại nếu có thay đổi
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== HIỂN THỊ OPTIONS THÊM TOPPING ==========
  void _showAddOptionsForToppingTab(BuildContext context) {
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
            // ===== NÚT THÊM NHÓM TOPPING =====
            ListTile(
              leading: Icon(Icons.add_box, color: Colors.teal[900]),
              title: Text('Thêm nhóm Topping'),
              onTap: () async {
                Navigator.pop(context);
                // Mở màn hình ToppingScreen không truyền topping = chế độ thêm mới
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToppingScreen(),
                  ),
                );
                if (result == true) _loadData(); // Tải lại nếu có thay đổi
              },
            ),
          ],
        ),
      ),
    );
  }
}
