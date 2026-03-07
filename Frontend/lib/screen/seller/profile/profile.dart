import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../config/api_config.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ========== KHAI BÁO BIẾN ==========
  Map<String, dynamic>? _profileData; // Dữ liệu profile
  bool _isLoading = true; // Trạng thái đang tải

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

  // ========== ĐĂNG XUẤT ==========
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đăng xuất'),
        content: Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Xóa token hoặc session ở đây nếu có
      // await TokenStorage.deleteToken();

      // Quay về màn hình login
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng xuất thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
          // ===== NÚT ĐĂNG XUẤT =====
          IconButton(
            icon: Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Đăng xuất',
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
          SizedBox(height: 24),
          // ===== NÚT ĐĂNG XUẤT LỚN =====
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout),
              label: Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red, width: 2),
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
          SizedBox(height: 24),
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

  // ========== HIỂN THỊ MỘT DÒNG THÔNG TIN ==========
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal[900], size: 24),
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

// ========== MÀN HÌNH CHỈNH SỬA PROFILE ==========
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile; // Profile cần chỉnh sửa (bắt buộc)

  const EditProfileScreen({super.key, required this.profile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _sdtController = TextEditingController();
  final _liveController = TextEditingController();

  String? _imageBase64;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load dữ liệu hiện tại vào form
    _nameController.text = widget.profile['name'] ?? '';
    _sdtController.text = widget.profile['sdt'] ?? '';
    _liveController.text = widget.profile['live'] ?? '';
    _imageBase64 = widget.profile['img'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sdtController.dispose();
    _liveController.dispose();
    super.dispose();
  }

  // ========== CHỌN ẢNH ==========
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await File(image.path).readAsBytes();
      setState(() {
        _imageBase64 = 'data:image/png;base64,${base64Encode(bytes)}';
      });
    }
  }

  // ========== LƯU THÔNG TIN ==========
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text,
        'sdt': _sdtController.text,
        'live': _liveController.text,
        'img': _imageBase64,
      };

      final response = await http.put(
        Uri.parse('${ApiConfig.profileUrl}${widget.profile['id']}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thông tin thành công'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Trả về true để reload
      } else {
        throw Exception('Lỗi: ${response.body}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa hồ sơ'),
        backgroundColor: Colors.teal[900],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // ===== CHỌN ẢNH =====
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    image: _imageBase64 != null && _imageBase64!.isNotEmpty
                        ? DecorationImage(
                            image: MemoryImage(
                              base64Decode(_imageBase64!.split(',').last),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _imageBase64 == null || _imageBase64!.isEmpty
                      ? Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey[600])
                      : null,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Nhấn để thay đổi ảnh',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            SizedBox(height: 24),

            // ===== TÊN QUÁN =====
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên quán *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên quán';
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // ===== SỐ ĐIỆN THOẠI =====
            TextFormField(
              controller: _sdtController,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),

            // ===== ĐỊA CHỈ =====
            TextFormField(
              controller: _liveController,
              decoration: InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 32),

            // ===== NÚT LƯU =====
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[900],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Lưu thay đổi',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
