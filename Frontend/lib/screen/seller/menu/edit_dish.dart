import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../config/api_config.dart';
import 'package:image_picker/image_picker.dart';

class EditDish extends StatefulWidget {
  final Map<String, dynamic> dish;

  EditDish({required this.dish});

  @override
  _EditDishState createState() => _EditDishState();
}

class _EditDishState extends State<EditDish> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  late TextEditingController _groupController;

  int? _selectedCategoryId;
  String _selectedCategoryName = "Chọn danh mục";
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  File? _selectedImage;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.dish['name']);
    _priceController = TextEditingController(
      text: widget.dish['price'].toString(),
    );
    _descriptionController = TextEditingController(
      text: widget.dish['description'] ?? '',
    );
    _groupController = TextEditingController(text: widget.dish['group'] ?? '');
    _selectedCategoryId = widget.dish['category_id'];
    _existingImageBase64 = widget.dish['img'];
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.categoryUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _categories = data.cast<Map<String, dynamic>>();
          _isLoadingCategories = false;

          // Tìm tên category hiện tại
          final currentCategory = _categories.firstWhere(
            (cat) => cat['id'] == _selectedCategoryId,
            orElse: () => {'name': 'Chọn danh mục'},
          );
          _selectedCategoryName = currentCategory['name'];
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải danh mục: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _existingImageBase64 =
              null; // Clear existing image when new one selected
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectCategory() async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chưa có danh mục nào'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn danh mục'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return ListTile(
                title: Text(category['name']),
                onTap: () => Navigator.pop(context, category),
              );
            },
          ),
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedCategoryId = selected['id'];
        _selectedCategoryName = selected['name'];
      });
    }
  }

  Future<void> _updateDish() async {
    // Validation
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập tên món'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập giá'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn danh mục'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    double? price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Giá không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Xác định ảnh để gửi lên
      String? imageBase64;
      if (_selectedImage != null) {
        // Có ảnh mới được chọn
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (_existingImageBase64 != null) {
        // Giữ ảnh cũ
        imageBase64 = _existingImageBase64;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.dishUrl}${widget.dish['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text.trim(),
          'price': price,
          'category_id': _selectedCategoryId,
          'img': imageBase64,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'group': _groupController.text.trim().isEmpty
              ? null
              : _groupController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Cập nhật món ăn thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        final error = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['detail'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi kết nối: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sửa món',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildInputRow("Tên*", "VD: Khoai tây chiên", _nameController),
                _buildImageUploadSection(),
                _buildInputRow(
                  "Giá*",
                  "đ",
                  _priceController,
                  keyboardType: TextInputType.number,
                ),
                _buildSelectionRow(
                  "Danh mục*",
                  _selectedCategoryName,
                  onTap: _selectCategory,
                ),
                _buildInputRow(
                  "Mô tả",
                  "VD: Cà chua + Khoai tây chiên + Tương ớt",
                  _descriptionController,
                  maxLines: 3,
                ),
                SizedBox(height: 12),
                _buildInputRow("Nhóm Topping", "VD: Topping", _groupController),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildInputRow(
    String label,
    String placeholder,
    TextEditingController controller, {
    bool hasHelp = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label.split('*')[0], style: TextStyle(fontSize: 15)),
              if (label.contains('*'))
                Text('*', style: TextStyle(color: Colors.green[700])),
              if (hasHelp)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.right,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Ảnh món",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Món có ảnh sẽ được khách đặt nhiều hơn. Tỷ lệ ảnh yêu cầu 1:1.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        )
                      : _existingImageBase64 != null &&
                            _existingImageBase64!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.memory(
                            base64Decode(_existingImageBase64!.split(',').last),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.orange[800]),
                            Text(
                              "Tải ảnh",
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildLinkText("Bí quyết để có ảnh món bắt mắt >"),
          _buildLinkText("Các lỗi ảnh món thường gặp >"),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildLinkText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(color: Colors.blue[700], fontSize: 14),
      ),
    );
  }

  Widget _buildSelectionRow(
    String label,
    String value, {
    bool hasHelp = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Text(label.split('*')[0], style: TextStyle(fontSize: 15)),
            if (label.contains('*'))
              Text('*', style: TextStyle(color: Colors.red)),
            if (hasHelp) Icon(Icons.help_outline, size: 16, color: Colors.grey),
            Spacer(),
            Text(
              value,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateDish,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[700],
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Cập nhật',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
