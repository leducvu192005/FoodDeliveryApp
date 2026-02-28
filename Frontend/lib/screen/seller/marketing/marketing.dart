import 'package:flutter/material.dart';
import 'discount_codes.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});
  _MarketingScreenState createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Marketing',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== THỐNG KÊ NHANH =====
            Text(
              'Thống kê',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Lượt xem',
                    '1,234',
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Đơn hàng',
                    '89',
                    Icons.shopping_cart,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Doanh thu',
                    '12.5M',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Đánh giá',
                    '4.5⭐',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),

            // ===== CÔNG CỤ MARKETING =====
            Text(
              'Công cụ Marketing',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildMarketingTool(
              'Mã giảm giá',
              'Tạo và quản lý mã giảm giá',
              Icons.local_offer,
              Colors.red,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DiscountCodesScreen(),
                  ),
                );
              },
            ),

            SizedBox(height: 12),
            _buildMarketingTool(
              'Thông báo khách hàng',
              'Gửi thông báo đến khách hàng',
              Icons.notifications,
              Colors.teal,
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Chức năng đang phát triển')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== CARD THỐNG KÊ ==========
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // ========== CARD CÔNG CỤ MARKETING ==========
  Widget _buildMarketingTool(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
