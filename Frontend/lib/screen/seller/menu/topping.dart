import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../config/api_config.dart';

// ============================================================
// TOPPING SCREEN - GỘP THÊM VÀ SỬA NHÓM TOPPING
// ============================================================
class ToppingScreen extends StatefulWidget {
  final Map<String, dynamic>? topping; // null = thêm mới, có giá trị = sửa

  ToppingScreen({this.topping});

  @override
  _ToppingScreenState createState() => _ToppingScreenState();
}

class _ToppingScreenState extends State<ToppingScreen> {
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _toppingItems = []; // Danh sách các topping items
  List<int> _selectedDishIds = []; // Danh sách món được chọn
  List<Map<String, dynamic>> _allDishes = []; // Tất cả món để chọn
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDishes();

    // ===== KHỞI TẠO - Nếu edit thì load dữ liệu cũ =====
    if (widget.topping != null) {
      _nameController.text = widget.topping!['name'] ?? '';
      _toppingItems = List<Map<String, dynamic>>.from(
        widget.topping!['items'] ?? [],
      );
      _selectedDishIds = List<int>.from(widget.topping!['dish_ids'] ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD DANH SÁCH TẤT CẢ MÓN ĂN
  // ============================================================
  Future<void> _loadDishes() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.dishUrl));
      if (response.statusCode == 200) {
        final List<dynamic> dishData = json.decode(response.body);
        setState(() {
          _allDishes = dishData.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi load món: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ============================================================
  // LƯU TOPPING (THÊM MỚI HOẶC CẬP NHẬT)
  // ============================================================
  Future<void> _saveTopping() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên nhóm topping')),
      );
      return;
    }

    if (_toppingItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng thêm ít nhất một topping')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = json.encode({
        'name': _nameController.text.trim(),
        'items': _toppingItems,
        'dish_ids': _selectedDishIds,
      });

      // ===== PHÂN BIỆT THÊM MỚI VÀ SỬA =====
      final bool isEdit = widget.topping != null;
      final response = isEdit
          ? await http.put(
              Uri.parse('${ApiConfig.toppingUrl}${widget.topping!['id']}'),
              headers: {'Content-Type': 'application/json'},
              body: body,
            )
          : await http.post(
              Uri.parse(ApiConfig.toppingUrl),
              headers: {'Content-Type': 'application/json'},
              body: body,
            );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Cập nhật nhóm topping thành công'
                  : 'Thêm nhóm topping thành công',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${error['detail']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // HIỂN THỊ DIALOG CHỌN MÓN ÁP DỤNG
  // ============================================================
  void _showDishSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Chọn món áp dụng',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _allDishes.length,
                  itemBuilder: (context, index) {
                    final dish = _allDishes[index];
                    final dishId = dish['id'];
                    final isSelected = _selectedDishIds.contains(dishId);

                    return CheckboxListTile(
                      title: Text(dish['name']),
                      subtitle: Text('đ ${dish['price']}'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true) {
                            _selectedDishIds.add(dishId);
                          } else {
                            _selectedDishIds.remove(dishId);
                          }
                        });
                        setState(() {}); // Cập nhật UI chính
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[900],
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('Xong', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HIỂN THỊ DIALOG THÊM/SỬA TOPPING ITEM
  // ============================================================
  void _showAddToppingItemDialog({int? editIndex}) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController priceController = TextEditingController();

    // ===== Nếu đang sửa, load dữ liệu cũ =====
    if (editIndex != null) {
      nameController.text = _toppingItems[editIndex]['name'];
      priceController.text = _toppingItems[editIndex]['price'].toString();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editIndex == null ? 'Thêm Topping' : 'Sửa Topping'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Tên topping*',
                hintText: 'VD: Size M',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá tiền*',
                hintText: 'VD: 5000',
                border: OutlineInputBorder(),
              ),
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
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui lòng nhập tên topping')),
                );
                return;
              }

              final price = double.tryParse(priceController.text) ?? 0;

              setState(() {
                if (editIndex == null) {
                  // ===== THÊM MỚI =====
                  _toppingItems.add({
                    'name': nameController.text.trim(),
                    'price': price,
                  });
                } else {
                  // ===== SỬA =====
                  _toppingItems[editIndex] = {
                    'name': nameController.text.trim(),
                    'price': price,
                  };
                }
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal[900]),
            child: Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // XÓA TOPPING ITEM
  // ============================================================
  void _deleteToppingItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa topping'),
        content: Text('Bạn có chắc muốn xóa topping này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _toppingItems.removeAt(index); // ===== XÓA =====
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.topping != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Sửa nhóm Topping' : 'Thêm nhóm Topping',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                // ===== Ô NHẬP TÊN NHÓM =====
                _buildInputSection('Tên nhóm*', 'VD: Size', _nameController),
                SizedBox(height: 8),

                // ===== DANH SÁCH TOPPING ITEMS =====
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Các topping*',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      // Hiển thị danh sách items
                      ..._toppingItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> item = entry.value;
                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Text('đ ${item['price']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ===== NÚT SỬA =====
                              IconButton(
                                icon: Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showAddToppingItemDialog(editIndex: index),
                              ),
                              // ===== NÚT XÓA =====
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteToppingItem(index),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      // ===== NÚT THÊM TOPPING ITEM =====
                      InkWell(
                        onTap: () => _showAddToppingItemDialog(),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            '+ Thêm Topping',
                            style: TextStyle(
                              color: Colors.teal[700],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),

                // ===== CHỌN MÓN ÁP DỤNG =====
                _buildListTile(
                  'Món đã liên kết',
                  trailingText: _selectedDishIds.isEmpty
                      ? 'Chọn món áp dụng'
                      : '${_selectedDishIds.length} món',
                  onTap: _showDishSelector,
                ),
              ],
            ),
          ),

          // ===== NÚT LƯU Ở DƯỚI CÙNG =====
          Container(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveTopping,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      isEdit ? 'Cập nhật' : 'Lưu',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: Ô NHẬP TÊN
  // ============================================================
  Widget _buildInputSection(
    String label,
    String hint,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: 15)),
          SizedBox(width: 20),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: DÒNG CHỌN (ListTile)
  // ============================================================
  Widget _buildListTile(
    String title, {
    String? trailingText,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(top: 1),
      color: Colors.white,
      child: ListTile(
        title: Text(title, style: TextStyle(fontSize: 15)),
        trailing: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (trailingText != null)
              Text(trailingText, style: TextStyle(color: Colors.grey)),
            trailing ?? Icon(Icons.chevron_right, size: 20),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}