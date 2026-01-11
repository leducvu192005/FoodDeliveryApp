import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../config/api_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDish extends StatefulWidget {
  @override
  _AddDishState createState() => _AddDishState();
}

class _AddDishState extends State<AddDish> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();

  int? _selectedCategoryId;
  String _selectedCategoryName = "Chọn danh mục";
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  bool _isLoadingCategories = true;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
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

  // ================== LOAD CATEGORY ==================
  Future<void> _loadCategories() async {
    try {
      final response = await http.get(Uri.parse(ApiConfig.categoryUrl));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _categories = data.cast<Map<String, dynamic>>();
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      _isLoadingCategories = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi tải danh mục: $e')));
    }
  }

  void _selectCategory() {
    if (_isLoadingCategories) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView.builder(
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final category = _categories[index];
            return ListTile(
              title: Text(category['name']),
              onTap: () {
                setState(() {
                  _selectedCategoryId = category['id'];
                  _selectedCategoryName = category['name'];
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  // ================== PICK IMAGE ==================
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ================== UPLOAD IMAGE (LOGIC MỚI) ==================
  Future<String?> _uploadImageToSupabase(File file) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'dishes/${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('dish-images')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return supabase.storage.from('dish-images').getPublicUrl(fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi upload ảnh: $e')));
      return null;
    }
  }

  // ================== SAVE DISH (ĐÃ SỬA GỌN) ==================
  Future<void> _saveDish() async {
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đủ thông tin')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giá không hợp lệ')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImageToSupabase(_selectedImage!);
        if (imageUrl == null) return;
      }

      final response = await http.post(
        Uri.parse(ApiConfig.dishUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text.trim(),
          'price': price,
          'category_id': _selectedCategoryId,
          'img': imageUrl,
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'group': _groupController.text.trim().isEmpty
              ? null
              : _groupController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thêm món ăn thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi lưu món ăn')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.green[700]),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thêm món',
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
                  "VD: Cà chua + Khoai tây chiên",
                  _descriptionController,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                _buildInputRow("Nhóm Topping", "VD: Topping", _groupController),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // Widget cho các dòng nhập liệu văn bản
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

  // Widget cho phần tải ảnh món ăn
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

  // Widget cho các dòng chọn (chuyển trang)
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
        onPressed: _isLoading ? null : _saveDish,
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
                'Lưu',
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
