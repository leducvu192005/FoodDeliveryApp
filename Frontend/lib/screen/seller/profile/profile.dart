import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../config/api_config.dart';
import '../../../services/auth_services.dart';
import '../../../services/seller_services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ========== KHAI BÁO BIẾN ==========
  Map<String, dynamic>? _profileData; // Dữ liệu profile
  bool _isLoading = true; // Trạng thái đang tải
  double _walletBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile(); // Tải dữ liệu profile khi khởi tạo
    _loadWallet();
  }

  final _sellerService = SellerService();

  // ========== TẢI DỮ LIỆU PROFILE ==========
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final data = await _sellerService.getProfile();
      if (mounted) {
        setState(() => _profileData = data);
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== MỞ MÀN HÌNH CHỈNH SỬA PROFILE ==========
  void _openEditProfile() {
    if (_profileData == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          profile: _profileData!,
          sellerService: _sellerService,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadProfile();
      }
    });
  }

  // ========== TẢI SỐ DƯ VÍ ==========
  Future<void> _loadWallet() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      final resp = await http.get(
        Uri.parse(ApiConfig.path('/seller/wallet')),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() =>
              _walletBalance = (data['balance'] as num?)?.toDouble() ?? 0);
        }
      }
    } catch (_) {}
  }

  // ========== MỞ MÀN HÌNH VÍ ==========
  void _openWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SellerWalletScreen(balance: _walletBalance),
      ),
    ).then((_) => _loadWallet());
  }

  // ========== CHUYỂN SANG GIAO DIỆN BUYER ==========
  Future<void> _switchToBuyer() async {
    final res = await AuthService.switchRole('buyer');
    if (!mounted) return;
    if (res != null && res['error'] == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/buyer/layout',
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res?['error'] ?? 'Khong the chuyen role'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _switchToBuyer,
              icon: Icon(Icons.swap_horiz),
              label: Text('Chuyen sang giao dien Nguoi mua'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
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
        ],
      ),
    );
  }

  // ========== HIỂN THỊ NỘI DUNG PROFILE ==========
  Widget _buildProfileContent() {
    final isOnline = _profileData!['status'] == 'on';
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          // Icon quán
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
              child: Icon(Icons.store, size: 60, color: Colors.grey[600]),
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
          SizedBox(height: 6),
          // Trạng thái
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline
                  ? Colors.green.withAlpha(30)
                  : Colors.red.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isOnline ? 'Dang mo cua' : 'Dang nghi',
              style: TextStyle(
                color: isOnline ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 24),
          // Thông tin chi tiết
          _buildInfoCard(),
          SizedBox(height: 16),
          // ===== VÍ SELLER =====
          _buildWalletCard(),
          SizedBox(height: 24),
          // ===== NÚT ĐĂNG XUẤT LỚN =====
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _switchToBuyer,
              icon: Icon(Icons.swap_horiz),
              label: Text('Chuyen sang giao dien Nguoi mua'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
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
            'So dien thoai',
            _profileData!['phone'] ?? 'Chua co',
          ),
          Divider(height: 1),
          _buildInfoRow(
            Icons.location_on,
            'Dia chi',
            _profileData!['address'] ?? 'Chua co',
          ),
          Divider(height: 1),
          _buildInfoRow(
            Icons.email,
            'Email',
            _profileData!['email'] ?? 'Chua co',
          ),
          Divider(height: 1),
          _buildInfoRow(
            Icons.badge,
            'CCCD',
            _profileData!['cccd'] ?? 'Chua co',
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

  // ========== CARD VÍ SELLER ==========
  Widget _buildWalletCard() {
    return GestureDetector(
      onTap: _openWallet,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.deepOrange.withAlpha(60),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet, color: Colors.white, size: 36),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vi cua ban',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_formatMoney(_walletBalance)} d',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70, size: 28),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      final formatted = amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
      return formatted;
    }
    return amount.toStringAsFixed(0);
  }
}

// ========== MÀN HÌNH VÍ SELLER ==========
class SellerWalletScreen extends StatefulWidget {
  final double balance;
  const SellerWalletScreen({super.key, required this.balance});

  @override
  State<SellerWalletScreen> createState() => _SellerWalletScreenState();
}

class _SellerWalletScreenState extends State<SellerWalletScreen> {
  double _balance = 0;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _balance = widget.balance;
    _loadData();
  }

  Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final headers = await _authHeaders();
      final walletResp = await http.get(
        Uri.parse(ApiConfig.path('/seller/wallet')),
        headers: headers,
      );
      final historyResp = await http.get(
        Uri.parse(ApiConfig.path('/seller/wallet/history')),
        headers: headers,
      );
      if (mounted) {
        if (walletResp.statusCode == 200) {
          final data = jsonDecode(walletResp.body);
          _balance = (data['balance'] as num?)?.toDouble() ?? 0;
        }
        if (historyResp.statusCode == 200) {
          _history =
              List<Map<String, dynamic>>.from(jsonDecode(historyResp.body));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _showWithdrawDialog() {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Rut tien'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'So du hien tai: ${_formatMoney(_balance)} d',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'So tien rut (d)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                labelText: 'Ghi chu (tuy chon)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Vui long nhap so tien hop le')),
                );
                return;
              }
              if (amount > _balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('So du khong du')),
                );
                return;
              }
              Navigator.pop(ctx);
              await _doWithdraw(amount, noteCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text('Rut tien', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _doWithdraw(double amount, String note) async {
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.path('/seller/wallet/withdraw')),
        headers: await _authHeaders(),
        body: jsonEncode({
          'amount': amount,
          if (note.isNotEmpty) 'note': note,
        }),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rut tien thanh cong: ${_formatMoney(amount)} d'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadData();
      } else {
        final err = jsonDecode(resp.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err['detail'] ?? 'Rut tien that bai'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Loi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatMoney(double amount) {
    if (amount >= 1000) {
      return amount.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vi cua toi'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Balance card
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.deepOrange, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text('So du',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 14)),
                        SizedBox(height: 8),
                        Text(
                          '${_formatMoney(_balance)} d',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                _balance > 0 ? _showWithdrawDialog : null,
                            icon: Icon(Icons.arrow_downward),
                            label: Text('Rut tien'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepOrange,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Lich su rut tien',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  if (_history.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'Chua co lich su rut tien',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._history.map((h) => _buildHistoryItem(h)),
                ],
              ),
            ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> h) {
    final amount = (h['amount'] as num?)?.toDouble() ?? 0;
    final balanceBefore = (h['balance_before'] as num?)?.toDouble() ?? 0;
    final balanceAfter = (h['balance_after'] as num?)?.toDouble() ?? 0;
    final note = (h['note'] ?? '').toString();
    final createdAt = (h['created_at'] ?? '').toString();
    final status = (h['status'] ?? '').toString();

    String dateDisplay = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        dateDisplay =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateDisplay = createdAt;
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_downward, color: Colors.red, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rut tien',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                if (note.isNotEmpty)
                  Text(note,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(dateDisplay,
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${_formatMoney(amount)} d',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                'Con lai: ${_formatMoney(balanceAfter)} d',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== MÀN HÌNH CHỈNH SỬA PROFILE ==========
class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  final SellerService sellerService;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.sellerService,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.profile['name'] ?? '';
    _phoneController.text = widget.profile['phone'] ?? '';
    _addressController.text = widget.profile['address'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.sellerService.updateProfile({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cap nhat thong tin thanh cong'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chinh sua ho so'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Ten quan *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui long nhap ten quan';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'So dien thoai',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Dia chi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Luu thay doi',
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
