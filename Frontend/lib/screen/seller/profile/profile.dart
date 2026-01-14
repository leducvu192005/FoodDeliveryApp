import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ========== KHAI BÁO BIẾN ==========
  Map<String, dynamic>? _profileData; // Dữ liệu profile
  bool _isLoading = true; // Trạng thái đang tải
  int? _profileId; // ID của profile hiện tại

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Tải dữ liệu profile khi khởi tạo
  }

  // ========== TẢI DỮ LIỆU PROFILE ==========
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(ApiConfig.profileUrl));

      if (response.statusCode == 200) {
        final List<dynamic> profiles = json.decode(response.body);
        
        if (profiles.isNotEmpty) {
          // Lấy profile đầu tiên (hoặc theo user_id nếu có auth)
          setState(() {
            _profileData = profiles[0];
            _profileId = _profileData!['id'];
          });
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
      setState(() => _isLoading = false);
    }
  }

  // ========== MỞ MÀN HÌNH CHỈNH SỬA PROFILE ==========
  void _openEditProfile() {
    if (_profileData == null) return; // Không cho phép tạo mới
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          profile: _profileData!,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadProfile(); // Tải lại dữ liệu sau khi chỉnh sửa
      }
    });
  }

  // ========== BUILD UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Hồ sơ quán',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // ===== CHỈ HIỂN THỊ NÚT SỬA =====
          if (_profileData != null)
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: _openEditProfile,
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _profileData == null
              ? _buildEmptyProfile()
              : _buildProfileContent(),
    );
  }

  // ========== HIỂN THỊ KHI CHƯA CÓ PROFILE ==========
  Widget _buildEmptyProfile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 100, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có thông tin quán',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Liên hệ quản trị viên để tạo hồ sơ',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // ========== HIỂN THỊ NỘI DUNG PROFILE ==========
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          // Ảnh đại diện quán
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: _profileData!['img'] != null &&
                        _profileData!['img'].toString().isNotEmpty
                    ? DecorationImage(
                        image: MemoryImage(
                          base64Decode(_profileData!['img'].split(',').last),
                        ),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileData!['img'] == null ||
                      _profileData!['img'].toString().isEmpty
                  ? Icon(Icons.store, size: 60, color: Colors.grey[600])
                  : null,
            ),
          ),
          SizedBox(height: 16),
          // Tên quán
          Text(
            _profileData!['name'] ?? 'Chưa có tên',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          // Thông tin chi tiết
          _buildInfoCard(),
        ],
      ),
    );
  }

  // ========== CARD HIỂN THỊ THÔNG TIN ==========
  Widget _buildInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.phone,
            'Số điện thoại',
            _profileData!['sdt'] ?? 'Chưa có',
          ),
          Divider(height: 1),
          _buildInfoRow(
            Icons.location_on,
            'Địa chỉ',
            _profileData!['live'] ?? 'Chưa có',
          ),
        ],
      ),
    );
  }

  // ========== DÒNG THÔNG TIN ==========
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700], size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// EDIT PROFILE SCREEN - CHỈ SỬA PROFILE (KHÔNG THÊM MỚI)
// ============================================================
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile; // Bắt buộc phải có profile để sửa

  EditProfileScreen({required this.profile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ========== KHAI BÁO BIẾN ==========
  late TextEditingController _nameController;
  late TextEditingController _sdtController;
  late TextEditingController _liveController;

  File? _selectedImage;
  String? _existingImageBase64;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // ===== KHỞI TẠO - Load dữ liệu profile hiện tại =====
    _nameController = TextEditingController(text: widget.profile['name']);
    _sdtController = TextEditingController(text: widget.profile['sdt'] ?? '');
    _liveController = TextEditingController(text: widget.profile['live'] ?? '');
    _existingImageBase64 = widget.profile['img'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sdtController.dispose();
    _liveController.dispose();
    super.dispose();
  }

  // ========== CHỌN ẢNH TỪ GALLERY ==========
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
          _existingImageBase64 = null; // Xóa ảnh cũ khi chọn ảnh mới
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

  // ========== CẬP NHẬT PROFILE ==========
  Future<void> _updateProfile() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên quán')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Xử lý ảnh: chọn ảnh mới hoặc giữ ảnh cũ
      String? imageBase64;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      } else if (_existingImageBase64 != null) {
        imageBase64 = _existingImageBase64;
      }

      final body = {
        'name': _nameController.text.trim(),
        'sdt': _sdtController.text.trim().isEmpty 
            ? null 
            : _sdtController.text.trim(),
        'live': _liveController.text.trim().isEmpty 
            ? null 
            : _liveController.text.trim(),
        'img': imageBase64,
      };

      // ===== GỌI API CẬP NHẬT =====
      final response = await http.put(
        Uri.parse('${ApiConfig.profileUrl}${widget.profile['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thông tin thành công'),
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
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ========== BUILD UI ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Chỉnh sửa thông tin',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 24),
            // ===== ẢNH ĐẠI DIỆN QUÁN =====
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : _existingImageBase64 != null &&
                              _existingImageBase64!.isNotEmpty
                          ? DecorationImage(
                              image: MemoryImage(
                                base64Decode(_existingImageBase64!.split(',').last),
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                ),
                child: _selectedImage == null &&
                        (_existingImageBase64 == null ||
                            _existingImageBase64!.isEmpty)
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 30, color: Colors.grey[600]),
                          SizedBox(height: 4),
                          Text(
                            'Thêm ảnh',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 24),
            // ===== FORM NHẬP LIỆU =====
            _buildInputField('Tên quán*', _nameController, Icons.store),
            _buildInputField(
              'Số điện thoại',
              _sdtController,
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildInputField(
              'Địa chỉ',
              _liveController,
              Icons.location_on,
            ),
            SizedBox(height: 24),
            // ===== NÚT CẬP NHẬT =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[900],
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Cập nhật',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET: Ô NHẬP LIỆU ==========
  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[700]),
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}