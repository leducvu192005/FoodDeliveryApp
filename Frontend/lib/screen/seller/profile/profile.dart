import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isShopOpen = true; // Trạng thái đóng/mở cửa hàng

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền xám nhẹ cho tách biệt các khối
      appBar: AppBar(
        title: Text('Tài khoản', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.black),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 12),
            _buildSection([
              _buildMenuItem(Icons.storefront, 'Cài đặt quán', 'Chỉnh sửa thông tin, giờ hoạt động'),
              _buildDivider(),
              _buildMenuItem(Icons.print_outlined, 'Cài đặt máy in', 'Kết nối máy in bluetooth/wifi'),
            ]),
            SizedBox(height: 12),
            _buildSection([
              _buildMenuItem(Icons.help_outline, 'Trung tâm trợ giúp', null),
              _buildDivider(),
              _buildMenuItem(Icons.policy_outlined, 'Quy chế hoạt động', null),
              _buildDivider(),
              _buildMenuItem(Icons.star_outline, 'Đánh giá ứng dụng', null),
            ]),
            SizedBox(height: 24),
            TextButton(
              onPressed: () {},
              child: Text('Đăng xuất', style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
            SizedBox(height: 20),
            Text('Phiên bản 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar quán
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.green[100],
            backgroundImage: NetworkImage('https://cdn-icons-png.flaticon.com/512/1046/1046784.png'), // Ảnh mẫu
          ),
          SizedBox(width: 16),
          // Thông tin tên và trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kitty Food', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('ID: 8839201', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isShopOpen ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isShopOpen ? 'ĐANG MỞ' : 'ĐÃ ĐÓNG',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: isShopOpen,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() {
                          isShopOpen = val;
                        });
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          Icon(Icons.qr_code, size: 30),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      color: Colors.white,
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String? subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {},
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 56, color: Colors.grey[200]);
  }
}